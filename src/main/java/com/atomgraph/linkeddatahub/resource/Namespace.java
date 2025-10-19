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

import com.atomgraph.client.util.Constructor;
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
import org.apache.jena.iri.IRI;
import org.apache.jena.iri.IRIFactory;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.system.Checker;
import org.apache.jena.update.UpdateRequest;
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

    /**
     * If SPARQL query is provided, returns its result over the in-memory namespace ontology graph.
     * If query is not provided
     * <ul>
     * <li>returns constructed instance if <samp>forClass</samp> URL param value (ontology class URI) is provided</li>
     * <li>otherwise, returns the namespace ontology graph (which is standalone, i.e. <em>not</em> the full ontology imports closure)</li>
     * </ul>
     * 
     * @param query SPARQL query string (optional)
     * @param defaultGraphUris default graph URI (ignored)
     * @param namedGraphUris named graph URIs (ignored)
     * 
     * {@link com.atomgraph.linkeddatahub.server.model.impl.Dispatcher#getNamespace()}
     * 
     * @return response
     */
    @Override
    @GET
    public Response get(@QueryParam(QUERY) Query query,
            @QueryParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @QueryParam(NAMED_GRAPH_URI) List<URI> namedGraphUris)
    {
        // if query param is not provided and the app is end-user, return the namespace ontology associated with this document
        if (query == null)
        {
            // construct instances for a list of ontology classes whose URIs are provided as ?forClass
            if (getUriInfo().getQueryParameters().containsKey(AC.forClass.getLocalName()))
            {
                List<String> forClasses = getUriInfo().getQueryParameters().get(AC.forClass.getLocalName());
                Model instances = ModelFactory.createDefaultModel();
                
                forClasses.stream().
                    map(forClass -> Optional.ofNullable(getOntology().getOntModel().getOntClass(checkURI(forClass).toString()))).
                    flatMap(Optional::stream).
                    forEach(forClass -> new Constructor().construct(forClass, instances, getApplication().getBase().getURI()));
                
                return getResponseBuilder(instances).build();
            }
            
            if (getApplication().canAs(EndUserApplication.class))
            {
                // the application ontology MUST use a <ns> URI! This is the URI this ontology endpoint is deployed on by the Dispatcher class
                String ontologyURI = getApplication().getOntology().getURI();
                if (log.isDebugEnabled()) log.debug("Returning namespace ontology from OntDocumentManager: {}", ontologyURI);
                // not returning the injected in-memory ontology because it has inferences applied to it
                OntologyModelGetter modelGetter = new OntologyModelGetter(getApplication().as(EndUserApplication.class), getSystem().getOntModelSpec(), getSystem().getOntologyQuery());
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
    
    /**
     * Checks URI syntax. Throws exception if invalid.
     * 
     * @param classIRIStr URI string
     * @return IRI
     */
    public static IRI checkURI(String classIRIStr)
    {
        if (classIRIStr == null) throw new IllegalArgumentException("URI String cannot be null");

        IRI classIRI = IRIFactory.iriImplementation().create(classIRIStr);
        // throws Exceptions on bad URIs:
        Checker.iriViolations(classIRI);

        return classIRI;
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