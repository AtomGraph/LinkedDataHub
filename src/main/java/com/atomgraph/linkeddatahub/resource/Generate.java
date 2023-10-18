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
import com.atomgraph.linkeddatahub.server.filter.response.BackendInvalidationFilter;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.atomgraph.spinrdf.vocabulary.SP;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import java.util.Calendar;
import java.util.Optional;
import java.util.UUID;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
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
import org.glassfish.jersey.uri.UriComponent;
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
    
    /**
     * Constructs endpoint for container generation.
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
                    
                    URI containerGraphURI = UriBuilder.fromUri(parent.getURI()).path("{slug}/").build(UUID.randomUUID().toString());
                    Model containerModel = ModelFactory.createDefaultModel();
                    
                    createContainer(containerModel,
                        containerGraphURI, parent,
                        cls.getLocalName() + "s",
                        createContent(containerModel, createContainerSelect(containerModel,
                            "Select " + cls.getLocalName(),
                            pss.asQuery(),
                            service)));
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
            
            // ban the parent container URI from proxy cache to make sure the next query using it will be fresh (e.g. SELECT that loads children)
            ban(getApplication().getService().getBackendProxy(), parent.getURI());
            
            return Response.ok().build();
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Creates <code>SELECT</code> SPARQL query.
     * 
     * @param model RDF model
     * @param title query title
     * @param query query object
     * @param service SPARQL service resource
     * @return query resource
     */
    public Resource createContainerSelect(Model model, String title, Query query, Resource service)
    {
        return model.createResource().
            addProperty(RDF.type, SP.Select).
            addLiteral(DCTerms.title, title).
            addProperty(SP.text, query.toString()).
            addProperty(LDH.service, service);
    }
    
    /**
     * Creates a container document.
     * 
     * @param model RDF model
     * @param graphURI named graph URI
     * @param parent parent document resource
     * @param title document title
     * @param content document content
     * @return container resource
     */
    public Resource createContainer(Model model, URI graphURI, Resource parent, String title, Resource content)
    {
        return model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Container).
            addProperty(SIOC.HAS_PARENT, parent).
            addLiteral(DCTerms.title, title).
            addLiteral(DH.slug, UUID.randomUUID().toString()).
            addLiteral(DCTerms.created, Calendar.getInstance()).
            addProperty(ResourceFactory.createProperty(RDF.getURI(), "_1"), content);
    }
    
    /**
     * Creates content resource.
     * 
     * @param model RDF model
     * @param query query resource
     * @return content resource
     */
    public Resource createContent(Model model, Resource query)
    {
        return model.createResource().
            addProperty(RDF.type, LDH.Content).
            addProperty(RDF.value, query);
    }
    
    /** 
     * Bans URL from the backend proxy cache.
     * 
     * @param proxy proxy server URL
     * @param url banned URL
     * @return proxy server response
     */
    public Response ban(Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        return getSystem().getClient().target(proxy.getURI()).request().
            header(BackendInvalidationFilter.HEADER_NAME, UriComponent.encode(url, UriComponent.Type.UNRESERVED)). // the value has to be URL-encoded in order to match request URLs in Varnish
            method("BAN", Response.class);
    }
    
}