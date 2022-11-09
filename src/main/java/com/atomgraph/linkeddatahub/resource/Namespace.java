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

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
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
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.Consumes;
import javax.ws.rs.FormParam;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.ResultSetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.sparql.resultset.ResultSetMem;
import org.apache.jena.sparql.vocabulary.ResultSetGraphVocab;
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
    private final Application application;
    private final Ontology ontology;
    private final SecurityContext securityContext;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs endpoint.
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
        this.application = application;
        this.ontology = ontology.get();
        this.securityContext = securityContext;
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
            if (getApplication().canAs(EndUserApplication.class))
            {
                String ontologyURI = getURI().toString() + "#"; // TO-DO: hard-coding "#" is not great. Replace with RDF property lookup.
                if (log.isDebugEnabled()) log.debug("Returning namespace ontology from OntDocumentManager: {}", ontologyURI);
                OntologyModelGetter modelGetter = new OntologyModelGetter(getApplication().as(EndUserApplication.class),
                        getSystem().getOntModelSpec(), getSystem().getOntologyQuery(), getSystem().getClient(), getSystem().getMediaTypes());
                return getResponseBuilder(modelGetter.getModel(ontologyURI)).build();
            }
            else throw new BadRequestException("SPARQL query string not provided");
        }
        
        return super.get(query, defaultGraphUris, namedGraphUris);
    }
    
//    @Override
//    public Response.ResponseBuilder getResponseBuilder(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
//    {
//        // if query param is not provided and the app is end-user, return the namespace ontology associated with this document
//        if (query == null)
//        {
//            if (getApplication().canAs(EndUserApplication.class))
//            {
//                String ontologyURI = getURI().toString() + "#"; // TO-DO: hard-coding "#" is not great. Replace with RDF property lookup.
//                if (log.isDebugEnabled()) log.debug("Returning namespace ontology from OntDocumentManager: {}", ontologyURI);
//                OntologyModelGetter modelGetter = new OntologyModelGetter(getApplication().as(EndUserApplication.class),
//                        getSystem().getOntModelSpec(), getSystem().getOntologyQuery(), getSystem().getClient(), getSystem().getMediaTypes());
//                return getResponseBuilder(modelGetter.getModel(ontologyURI));
//            }
//            else throw new BadRequestException("SPARQL query string not provided");
//        }
//
//       return super.getResponseBuilder(query, defaultGraphUris, namedGraphUris);
//        if (query.isSelectType())
//        {
//            if (log.isDebugEnabled()) log.debug("Loading ResultSet using SELECT/ASK query: {}", query);
//            return getResponseBuilder(new ResultSetMem(QueryExecution.create(query, getOntology().getOntModel()).execSelect()));
//        }
//        if (query.isAskType())
//        {
//            Model model = ModelFactory.createDefaultModel();
//            model.createResource().
//                addProperty(RDF.type, ResultSetGraphVocab.ResultSet).
//                addLiteral(ResultSetGraphVocab.p_boolean, QueryExecution.create(query, getOntology().getOntModel()).execAsk());
//                
//            if (log.isDebugEnabled()) log.debug("Loading ResultSet using SELECT/ASK query: {}", query);
//            return getResponseBuilder(ResultSetFactory.copyResults(ResultSetFactory.makeResults(model)));
//        }
//
//        if (query.isDescribeType())
//        {
//            if (log.isDebugEnabled()) log.debug("Loading Model using CONSTRUCT/DESCRIBE query: {}", query);
//            return getResponseBuilder(QueryExecution.create(query, getOntology().getOntModel()).execDescribe());
//        }
//        
//        if (query.isConstructType())
//        {
//            if (log.isDebugEnabled()) log.debug("Loading Model using CONSTRUCT/DESCRIBE query: {}", query);
//            return getResponseBuilder(QueryExecution.create(query, getOntology().getOntModel()).execConstruct());
//        }
//        
//        if (log.isWarnEnabled()) log.warn("SPARQL endpoint received unknown type of query: {}", query);
//        throw new BadRequestException("Unknown query type");
//    }
    
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
     * Returns URI of this resource.
     * 
     * @return resource URI
     */
    public URI getURI()
    {
        return uri;
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
     * Returns application ontology.
     * 
     * @return ontology resource
     */
    public Ontology getOntology()
    {
        return ontology;
    }
    
    /**
     * Returns JAX-RS security context.
     * 
     * @return security context
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
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