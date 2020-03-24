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

import com.sun.jersey.api.core.HttpContext;
import com.sun.jersey.api.core.ResourceContext;
import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.util.List;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.Variant;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.client.DataManager;
import com.atomgraph.processor.util.TemplateCall;
import com.sun.jersey.api.client.Client;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.PostConstruct;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves uploaded file data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends ResourceBase
{
    private static final Logger log = LoggerFactory.getLogger(Item.class);
    
    public Item(@Context UriInfo uriInfo, @Context ClientUriInfo clientUriInfo, @Context Request request, @Context MediaTypes mediaTypes,
            @Context Service service, @Context com.atomgraph.linkeddatahub.apps.model.Application application,
            @Context Ontology ontology, @Context TemplateCall templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context Client client,
            @Context HttpContext httpContext, @Context SecurityContext securityContext,
            @Context DataManager dataManager, @Context Providers providers,
            @Context Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext,
                client,
                httpContext, securityContext,
                dataManager, providers,
                system);
    }

    @PostConstruct
    public void init()
    {
        // InfModel too expensive to create on each request
        getOntResource().getOntModel().add(describe().getDefaultModel());
    }
    
    @Override
    public ResponseBuilder getResponseBuilder(Dataset dataset)
    {
        List<Variant> variants = getVariants(getWritableMediaTypes(Dataset.class));
        Variant variant = getRequest().selectVariant(variants);
        if (variant == null)
        {
            if (log.isTraceEnabled()) log.trace("Requested Variant {} is not on the list of acceptable Response Variants: {}", variant, variants);
            throw new WebApplicationException(Response.status(Response.Status.NOT_ACCEPTABLE).build());
        }
        
        // respond with file content if Variant is compatible with the File's MediaType. otherwise, send RDF
        if (getFormat().isCompatible(variant.getMediaType()))
        {
            URI fileURI = getSystem().getUploadRoot().resolve(getUriInfo().getPath());
            File file = new File(fileURI);

            try
            {
                if (!file.exists()) throw new FileNotFoundException();

                return super.getResponseBuilder(dataset).entity(file).
                        type(variant.getMediaType());
                //header("Content-Disposition", "attachment; filename=\"" + getRequiredProperty(NFO.fileName).getString() + "\"").
            }
            catch (FileNotFoundException ex)
            {
                if (log.isWarnEnabled()) log.warn("File with URI '{}' not found", fileURI);
                throw new WebApplicationException(ex, Response.Status.NOT_FOUND);
            }
        }
        
        return super.getResponseBuilder(dataset);
    }
    
    public javax.ws.rs.core.MediaType getFormat()
    {
        Resource format = getOntResource().getPropertyResourceValue(DCTerms.format);
        if (format == null)
        {
            if (log.isErrorEnabled()) log.error("File '{}' does not have a media type", getOntResource());
            throw new IllegalStateException("File does not have a media type (dct:format)");
        }
        
        return com.atomgraph.linkeddatahub.MediaType.valueOf(format);
    }
    
    @Override
    public List<javax.ws.rs.core.MediaType> getWritableMediaTypes(Class clazz)
    {
        List<javax.ws.rs.core.MediaType> list = new ArrayList<>();
        list.add(getFormat());

        return list;
    }
    
}
