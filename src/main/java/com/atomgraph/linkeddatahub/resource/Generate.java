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

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.imports.QueryLoader;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.Syntax;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that generates containers for given classes.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Generate extends Add
{

    private static final Logger log = LoggerFactory.getLogger(Generate.class);

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
     * @param dataManager RDF data manager
     */
    @Inject
    public Generate(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system,
            DataManager dataManager)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
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

            Resource queryRes = arg.getPropertyResourceValue(SPIN.query);
            if (queryRes == null) throw new BadRequestException("Transformation query string (spin:query) not provided");

            LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
            QueryLoader queryLoader = new QueryLoader(URI.create(queryRes.getURI()), getApplication().getBase().getURI(), Syntax.syntaxARQ, ldc);
            Query query = queryLoader.get();
            if (!query.isConstructType()) throw new BadRequestException("Transformation query is not of CONSTRUCT type");

            Model importModel = ldc.getModel(source.getURI());
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
    
}
