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
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.imports.QueryLoader;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.atomgraph.spinrdf.vocabulary.SP;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.Syntax;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that generates containers for given classes.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Generate extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Generate.class);
    
    /** Relative URL of the query container */
    public static final String QUERY_PATH = "queries/";

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
        ResIterator it = model.listSubjectsWithProperty(LDH.service);
        try
        {
            if (!it.hasNext()) throw new BadRequestException("Argument resource not provided");
            
            Resource arg = it.next();
            Resource service = arg.getPropertyResourceValue(LDH.service);
            if (service == null) throw new BadRequestException("Service URI (ldh:service) not provided");

            Resource parent = arg.getPropertyResourceValue(SIOC.HAS_PARENT);
            if (parent == null) throw new BadRequestException("Parent container (sioc:has_parent) not provided");

            ResIterator partIt = model.listSubjectsWithProperty(VoID._class);
            try
            {
                while (partIt.hasNext())
                {
                    Resource part = partIt.next();
                    Resource cls = part.getPropertyResourceValue(VoID._class);
                    Resource queryRes = part.getPropertyResourceValue(SPIN.query);
                    if (queryRes == null) throw new BadRequestException("Container query string (spin:query) not provided");

                    LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                        delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
                    QueryLoader queryLoader = new QueryLoader(URI.create(queryRes.getURI()), getApplication().getBase().getURI(), Syntax.syntaxARQ, ldc);
                    Query query = queryLoader.get();
                    if (!query.isSelectType()) throw new BadRequestException("Container query is not of SELECT type");
                    
                    ParameterizedSparqlString pss = new ParameterizedSparqlString(query.toString());
                    pss.setIri(RDF.type.getLocalName(), cls.getURI()); // inject $type value
                    
                    Model containerQueryModel = ModelFactory.createDefaultModel();
                    URI containerQueryGraphURI = getUriInfo().getBaseUriBuilder().path(QUERY_PATH).path("{slug}/").build(UUID.randomUUID().toString());
                    createContainerQuery(containerQueryModel,
                        containerQueryGraphURI,
                        containerQueryModel.createResource(getUriInfo().getBaseUri().resolve(QUERY_PATH).toString()),
                        "Select " + cls.getLocalName(),
                        pss.asQuery(),
                        service);
                    new Skolemizer(containerQueryGraphURI.toString()).apply(containerQueryModel);
                    
                    Response queryResponse = super.post(containerQueryModel, false, containerQueryGraphURI);
                    if (queryResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Cannot create Query");
                        throw new InternalServerErrorException("Cannot create Query");
                    }

                    Resource containerQuery = containerQueryModel.createResource(containerQueryGraphURI.toString()).getPropertyResourceValue(FOAF.primaryTopic);
                    Model containerModel = ModelFactory.createDefaultModel();
                    URI containerGraphURI = UriBuilder.fromUri(parent.getURI()).path("{slug}/").build(UUID.randomUUID().toString());
                    createContainer(containerModel,
                        containerGraphURI, parent,
                        cls.getLocalName() + "s",
                        createContent(containerModel, containerQuery));
                    new Skolemizer(containerGraphURI.toString()).apply(containerModel);

                    Response containerResponse = super.post(containerModel, false, containerGraphURI);
                    if (containerResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Cannot create container");
                        throw new InternalServerErrorException("Cannot create container");
                    }
                }
            }
            finally
            {
                partIt.close();
            }
            
            return Response.ok().build();
        }
        finally
        {
            it.close();
        }
    }
    
     public Resource createContainerQuery(Model model, URI graphURI, Resource container, String title, Query query, Resource service)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DCTerms.title, title).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource queryRes = model.createResource().
            addProperty(RDF.type, SP.Select).
            addLiteral(DCTerms.title, title).
            addProperty(SP.text, query.toString()).
            addProperty(LDH.service, service);
        
        item.addProperty(FOAF.primaryTopic, queryRes);
        
        return queryRes;
    }
    
    public Resource createContainer(Model model, URI graphURI, Resource parent, String title, Resource content)
    {
        return model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Container).
            addProperty(SIOC.HAS_PARENT, parent).
            addLiteral(DCTerms.title, title).
            addLiteral(DH.slug, UUID.randomUUID().toString()).
            addProperty(ResourceFactory.createProperty(RDF.getURI(), "_1"), content);
    }
    
    public Resource createContent(Model model, Resource query)
    {
        return model.createResource().
            addProperty(RDF.type, LDH.Content).
            addProperty(RDF.value, query);
    }
    
}