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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import static com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import com.univocity.parsers.common.ParsingContext;
import com.univocity.parsers.common.processor.RowProcessor;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.net.URI;
import org.apache.jena.atlas.lib.IRILib;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class CSVGraphStoreRowProcessor implements RowProcessor // extends com.atomgraph.etl.csv.stream.CSVStreamRDFProcessor
{

    private static final Logger log = LoggerFactory.getLogger(CSVGraphStoreRowProcessor.class);

    private final Service service, adminService;
    private final LinkedDataClient ldc;
    private final String base;
    private final Query query;
    private int subjectCount, tripleCount;

    /**
     * Constructs row processor.
     * 
     * @param service SPARQL service of the application
     * @param adminService SPARQL service of the admin application
     * @param ldc Linked Data client
     * @param base base URI
     * @param query transformation query
     */
    public CSVGraphStoreRowProcessor(Service service, Service adminService, LinkedDataClient ldc, String base, Query query)
    {
        this.service = service;
        this.adminService = adminService;
        this.ldc = ldc;
        this.base = base;
        this.query = query;
    }

    @Override
    public void processStarted(ParsingContext context)
    {
        subjectCount = tripleCount = 0;
    }

    @Override
    public void rowProcessed(String[] row, ParsingContext context)
    {
        Dataset rowDataset = transformRow(row, context);
        
        // the default graph is ignored!
        
        rowDataset.listNames().forEachRemaining(graphUri -> 
            {
                // exceptions get swallowed by the client? TO-DO: wait for completion
                Model namedModel = rowDataset.getNamedModel(graphUri);
                if (!namedModel.isEmpty()) add(Entity.entity(namedModel, APPLICATION_NTRIPLES_TYPE), graphUri);
                
                try
                {
                    // purge cache entries that include the graph URI
                    if (getService().getBackendProxy() != null) ban(getService().getClient(), getService().getBackendProxy(), graphUri).close();
                    if (getAdminService() != null && getAdminService().getBackendProxy() != null) ban(getAdminService().getClient(), getAdminService().getBackendProxy(), graphUri).close();
                }
                catch (Exception e)
                {
                    if (log.isErrorEnabled()) log.error("Error banning URI <{}> from backend proxy cache", graphUri);
                }
            }
        );
    }
    
    /**
     * Creates a graph using <code>PUT</code> if it doesn't exist, otherwise appends data using <code>POST</code>.
     * 
     * @param entity request entity
     * @param graphURI the graph URI
     * @return JAX-RS response
     */
    protected Response add(Entity entity, String graphURI)
    {
        try (Response headResponse = getLinkedDataClient().head(URI.create(graphURI)))
        {
            if (headResponse.getStatus() == Response.Status.OK.getStatusCode()) // POST if graph already exists
            {
                try (Response cr = getLinkedDataClient().post(URI.create(graphURI), getLinkedDataClient().getReadableMediaTypes(Model.class), entity))
                {
                    if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using POST. Status code: {}", graphURI, cr.getStatus());
                        throw new ImportException(new IOException("RDF document with URI <" + graphURI + "> could not be successfully created using POST. Status code: " + cr.getStatus()));
                    }

                    return Response.status(cr.getStatus()).
                        entity(cr.readEntity(Model.class)).
                        build();
                }
            }
            else // PUT to create graph
            {
                try (Response cr = getLinkedDataClient().put(URI.create(graphURI), getLinkedDataClient().getReadableMediaTypes(Model.class), entity))
                {
                    if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using PUT. Status code: {}", graphURI, cr.getStatus());
                        throw new RuntimeException(new IOException("RDF document with URI <" + graphURI + "> could not be successfully created using PUT. Status code: " + cr.getStatus()));
                    }

                    return Response.status(cr.getStatus()).
                        entity(cr.readEntity(Model.class)).
                        build();
                }
            }
        }
    }
    
    /**
     * Transforms CSV row into an an RDF graph.
     * First a generic CSV/RDF graph is constructed. Then the transformation query is applied on it.
     * Extended SPARQL syntax is used to allow the <code>CONSTRUCT GRAPH</code> query form.
     * 
     * @param row CSV row
     * @param context parsing context
     * @return RDF result
     */
    public Dataset transformRow(String[] row, ParsingContext context)
    {
        Model rowModel = ModelFactory.createDefaultModel();
        Resource subject = rowModel.createResource();
        subjectCount++;
        
        int cellNo = 0;
        for (String cell : row)
        {
            if (cell != null && context.headers()[cellNo] != null)
            {
                String fragmentId = IRILib.encodeUriComponent(context.headers()[cellNo]);
                Property property = rowModel.createProperty(getBase(), "#" + fragmentId);
                subject.addProperty(property, cell);
                tripleCount++;
            }
            cellNo++;
        }

        try (QueryExecution qex = QueryExecution.create(getQuery(), rowModel))
        {
            return qex.execConstructDataset();
        }
    }
    
    @Override
    public void processEnded(ParsingContext context)
    {
    }

    /**
     * Bans a URL from proxy cache.
     * 
     * @param client HTTP client
     * @param proxy proxy cache endpoint
     * @param url request URL
     * @return response from cache
     */
    public Response ban(Client client, Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
        return client.
            target(proxy.getURI()).
            request().
            header("X-Escaped-Request-URI", UriComponent.encode(url, UriComponent.Type.UNRESERVED)).
            method("BAN", Response.class);
    }
    
    /**
     * Return application's SPARQL service.
     * 
     * @return SPARQL service
     */
    public Service getService()
    {
        return service;
    }
    
    /**
     * Return admin application's SPARQL service.
     * 
     * @return SPARQL service
     */
    public Service getAdminService()
    {
        return adminService;
    }
    
    /**
     * Returns base URI.
     * @return base URI string
     */
    public String getBase()
    {
        return base;
    }
    
    /**
     * Returns the transformation query.
     * 
     * @return SPARQL query
     */
    public Query getQuery()
    {
        return query;
    }
    
    /**
     * Returns the cumulative count of RDF subject resources.
     * 
     * @return subject count
     */
    public int getSubjectCount()
    {
        return subjectCount;
    }
    
    /**
     * Returns the cumulative count of RDF triples.
     * 
     * @return triple count
     */
    public int getTripleCount()
    {
        return tripleCount;
    }
    
    /**
     * Returns the HTTP client.
     * 
     * @return client object
     */
    public LinkedDataClient getLinkedDataClient()
    {
        return ldc;
    }
    
}
