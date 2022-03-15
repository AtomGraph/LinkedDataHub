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
import com.atomgraph.linkeddatahub.model.Service;
import static com.atomgraph.core.model.SPARQLEndpoint.DEFAULT_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.NAMED_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.QUERY;
import com.atomgraph.linkeddatahub.server.model.impl.SPARQLEndpointImpl;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.GET;
import javax.ws.rs.QueryParam;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.ResultSetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.sparql.resultset.ResultSetMem;
import org.apache.jena.sparql.vocabulary.ResultSetGraphVocab;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves in-memory ontology as a SPARQL endpoint.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Namespace extends SPARQLEndpointImpl
{

    private static final Logger log = LoggerFactory.getLogger(Namespace.class);

    private final Ontology ontology;
    
    /**
     * Constructs endpoint.
     * 
     * @param request current request
     * @param service SPARQL service
     * @param ontology ontology of the current application
     * @param mediaTypes registry of readable/writable media types
     * @param system system application
     */
    @Inject
    public Namespace(@Context Request request, Optional<Service> service, Optional<Ontology> ontology, MediaTypes mediaTypes, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, service, mediaTypes);
        this.ontology = ontology.get();
    }

    @Override
    @GET
    public Response get(@QueryParam(QUERY) Query query,
            @QueryParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @QueryParam(NAMED_GRAPH_URI) List<URI> namedGraphUris)
    {
        return getResponseBuilder(query, defaultGraphUris, namedGraphUris).build();
    }
    
    @Override
    public Response.ResponseBuilder getResponseBuilder(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        if (query == null) throw new BadRequestException("Query string not provided");

        if (query.isSelectType())
        {
            if (log.isDebugEnabled()) log.debug("Loading ResultSet using SELECT/ASK query: {}", query);
            return getResponseBuilder(new ResultSetMem(QueryExecution.create(query, getOntology().getOntModel()).execSelect()));
        }
        if (query.isAskType())
        {
            Model model = ModelFactory.createDefaultModel();
            model.createResource().
                addProperty(RDF.type, ResultSetGraphVocab.ResultSet).
                addLiteral(ResultSetGraphVocab.p_boolean, QueryExecution.create(query, getOntology().getOntModel()).execAsk());
                
            if (log.isDebugEnabled()) log.debug("Loading ResultSet using SELECT/ASK query: {}", query);
            return getResponseBuilder(ResultSetFactory.copyResults(ResultSetFactory.makeResults(model)));
        }

        if (query.isDescribeType())
        {
            if (log.isDebugEnabled()) log.debug("Loading Model using CONSTRUCT/DESCRIBE query: {}", query);
            return getResponseBuilder(QueryExecution.create(query, getOntology().getOntModel()).execDescribe());
        }
        
        if (query.isConstructType())
        {
            if (log.isDebugEnabled()) log.debug("Loading Model using CONSTRUCT/DESCRIBE query: {}", query);
            return getResponseBuilder(QueryExecution.create(query, getOntology().getOntModel()).execConstruct());
        }
        
        if (log.isWarnEnabled()) log.warn("SPARQL endpoint received unknown type of query: {}", query);
        throw new BadRequestException("Unknown query type");
    }
    
    public Ontology getOntology()
    {
        return ontology;
    }
    
}