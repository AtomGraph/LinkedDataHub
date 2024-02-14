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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.client.vocabulary.AC;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import com.atomgraph.core.MediaTypes;
import static com.atomgraph.core.model.SPARQLEndpoint.DEFAULT_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.NAMED_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.QUERY;
import static com.atomgraph.core.model.SPARQLEndpoint.UPDATE;
import static com.atomgraph.core.model.SPARQLEndpoint.USING_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.USING_NAMED_GRAPH_URI;
import com.atomgraph.core.model.impl.dataset.ServiceImpl;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.server.util.OntologyModelGetter;
import com.atomgraph.spinrdf.vocabulary.SP;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves in-memory ontology as a SPARQL endpoint.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Namespace extends com.atomgraph.core.model.impl.SPARQLEndpointImpl
{

    private static final Logger log = LoggerFactory.getLogger(Namespace.class);

    private final URI uri;
    private final UriInfo uriInfo;
    private final Application application;
    private final Ontology ontology;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs endpoint from the in-memory ontology model.
     * 
     * @param request current request
     * @param uriInfo current request's URI info
     * @param application current end-user application
     * @param ontology application's ontology
     * @param mediaTypes registry of readable/writable media types
     * @param securityContext JAX-RS security context
     * @param system system application
     */
    @Inject
    public Namespace(@Context Request request, @Context UriInfo uriInfo, 
            Application application, Optional<Ontology> ontology, MediaTypes mediaTypes,
            @Context SecurityContext securityContext, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, new ServiceImpl(DatasetFactory.create(ontology.get().getOntModel()), mediaTypes), mediaTypes);
        this.uri = uriInfo.getAbsolutePath();
        this.uriInfo = uriInfo;
        this.application = application;
        this.ontology = ontology.get();
        this.system = system;
    }

    @Override
    @GET
    public Response get(@QueryParam(QUERY) Query query,
            @QueryParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @QueryParam(NAMED_GRAPH_URI) List<URI> namedGraphUris)
    {
        // if query param is not provided and the app is end-user, return the namespace ontology associated with this document
        if (query == null)
        {
            if (getUriInfo().getQueryParameters().containsKey(AC.forClass.getLocalName()))
            {
                String forClass = getUriInfo().getQueryParameters().getFirst(AC.forClass.getLocalName());
                Model constructed = constructForClass(forClass);
                return getResponseBuilder(constructed).build();
            }
            
            if (getApplication().canAs(EndUserApplication.class))
            {
                String ontologyURI = getURI().toString() + "#"; // TO-DO: hard-coding "#" is not great. Replace with RDF property lookup.
                if (log.isDebugEnabled()) log.debug("Returning namespace ontology from OntDocumentManager: {}", ontologyURI);
                // not returning the injected in-memory ontology because it has inferences applied to it
                OntologyModelGetter modelGetter = new OntologyModelGetter(getApplication().as(EndUserApplication.class),
                        getSystem().getOntModelSpec(), getSystem().getOntologyQuery(), getSystem().getClient(), getSystem().getMediaTypes());
                return getResponseBuilder(modelGetter.getModel(ontologyURI)).build();
            }
            else throw new BadRequestException("SPARQL query string not provided");
        }
        
        return super.get(query, defaultGraphUris, namedGraphUris);
    }
    
    @Override
    @POST
    @Consumes(com.atomgraph.core.MediaType.APPLICATION_FORM_URLENCODED)
    public Response post(@FormParam(QUERY) String queryString, @FormParam(UPDATE) String updateString,
            @FormParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @FormParam(NAMED_GRAPH_URI) List<URI> namedGraphUris,
            @FormParam(USING_GRAPH_URI) List<URI> usingGraphUris, @FormParam(USING_NAMED_GRAPH_URI) List<URI> usingNamedGraphUris)
    {
        if (updateString != null) throw new WebApplicationException("SPARQL updates are not allowed on the <ns> endpoint", Status.METHOD_NOT_ALLOWED);

        return super.post(queryString, updateString, defaultGraphUris, namedGraphUris, usingGraphUris, usingNamedGraphUris);
    }
    
    @Override
    @POST
    @Consumes(com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE)
    public Response post(UpdateRequest update, @QueryParam(USING_GRAPH_URI) List<URI> usingGraphUris, @QueryParam(USING_NAMED_GRAPH_URI) List<URI> usingNamedGraphUris)
    {
        throw new WebApplicationException("SPARQL updates are not allowed on the <ns> endpoint", Status.METHOD_NOT_ALLOWED);
    }
    
    public Model constructForClass(String forClass)
    {
        if (forClass == null) throw new IllegalArgumentException("forClass URI string cannot be null");

        Resource cls = getOntology().getModel().createResource(forClass);
        Model model = ModelFactory.createDefaultModel();
        Resource instance = model.createResource();
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(com.atomgraph.client.vocabulary.SPIN.THIS_VAR_NAME, instance);

        StmtIterator it = cls.listProperties(SPIN.constructor);
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                String constructString = stmt.getObject().asResource().getProperty(SP.text).getString();
                instance.addProperty(RDF.type, cls);
                
                try (QueryExecution qex = QueryExecution.model(model).
                    query(constructString).
                    initialBinding(qsm).
                    build())
                {
                    qex.execConstruct(model);
                }
            }
        }
        finally
        {
            it.close();
        }
        
        return model;
    }
    
    /**
     * Returns URI of this resource.
     * 
     * @return resource URI
     */
    public URI getURI()
    {
        return uri;
    }
    
    /**
     * Returns URI info for the current request.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns the ontology of the current application.
     * 
     * @return application ontology
     */
    public Ontology getOntology()
    {
        return ontology;
    }
    
    /**
     * Returns the system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}