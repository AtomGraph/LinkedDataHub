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
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint for cloning (copying) RDF data from remote RDF documents.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Clone extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(Clone.class);

    private final URI uri;
    
    /**
     * Constructs resource.
     * 
     * @param request current request
     * @param uriInfo URI info for the current request
     * @param mediaTypes registry of readable/writable media types
     * @param application current application
     * @param ontology ontology of the current application
     * @param service service of the current application
     * @param providers JAX-RS provider registry
     * @param system JAX-RS application
     */
    @Inject
    public Clone(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, providers, system);
        this.uri = uriInfo.getAbsolutePath();
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
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

            LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient().target(source.getURI()), getMediaTypes());
            
            return super.post(ldc.get(), false, URI.create(graph.getURI()));
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Returns URI of this resource.
     * 
     * @return URI
     */
    public URI getURI()
    {
        return uri;
    }

}
