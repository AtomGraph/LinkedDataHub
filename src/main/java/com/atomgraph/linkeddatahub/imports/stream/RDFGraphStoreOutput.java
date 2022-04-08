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
package com.atomgraph.linkeddatahub.imports.stream;

import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import java.io.InputStream;
import javax.ws.rs.client.Client;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.glassfish.jersey.uri.UriComponent;

/**
 * Reads RDF from input stream and writes it into a named graph.
 * If a transformation query is provided, the input is transformed before writing.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class RDFGraphStoreOutput
{

    private final Service service, adminService;
    private final GraphStoreClient graphStoreClient;
    private final String base;
    private final InputStream is;
    private final Query query;
    private final Lang lang;
    private final String graphURI;
    
    /**
     * Constructs output writer.
     * 
     * @param service SPARQL service of the application
     * @param adminService SPARQL service of the admin application
     * @param graphStoreClient GSP client for RDF results
     * @param is RDF input stream
     * @param base base URI
     * @param query <code>CONSTRUCT</code> transformation query or null
     * @param lang RDF language
     * @param graphURI named graph URI
     */
    public RDFGraphStoreOutput(Service service, Service adminService, GraphStoreClient graphStoreClient, InputStream is, String base, Query query, Lang lang, String graphURI)
    {
        this.service = service;
        this.adminService = adminService;
        this.graphStoreClient = graphStoreClient;
        this.is = is;
        this.base = base;
        this.query = query;
        this.lang = lang;
        this.graphURI = graphURI;
    }
    
    /**
     * Reads RDF and writes (possibly transformed) RDF into a named graph.
     * The input is transformed if the SPARQL transformation query was provided.
     * Extended SPARQL syntax is used to allow the <code>CONSTRUCT GRAPH</code> query form.
     */
    public void write()
    {
        Model model = ModelFactory.createDefaultModel();
        RDFDataMgr.read(model, getInputStream(), getBase(), getLang());

        if (getQuery() != null)
        {
            try (QueryExecution qex = QueryExecution.create(getQuery(), model))
            {
                Dataset dataset = qex.execConstructDataset();

                dataset.listNames().forEachRemaining(graphUri ->
                    {
                         // exceptions get swallowed by the client! TO-DO: wait for completion
                        if (!dataset.getNamedModel(graphUri).isEmpty()) getGraphStoreClient().add(graphUri, dataset.getNamedModel(graphUri));
                        
                        // purge cache entries that include the graph URI
                        if (getService().getProxy() != null) ban(getService().getClient(), getService().getProxy(), graphUri);
                        if (getAdminService() != null && getAdminService().getProxy() != null) ban(getAdminService().getClient(), getAdminService().getProxy(), graphUri);
                    }
                );
            }
        }
        else
        {
            if (getGraphURI() == null) throw new IllegalStateException("Neither RDFImport query nor graph name is specified");
            
            getGraphStoreClient().add(getGraphURI(), model); // exceptions get swallowed by the client! TO-DO: wait for completion
            
            // purge cache entries that include the graph URI
            if (getService().getProxy() != null) ban(getService().getClient(), getService().getProxy(), getGraphURI());
            if (getAdminService() != null && getAdminService().getProxy() != null) ban(getAdminService().getClient(), getAdminService().getProxy(), getGraphURI());
        }
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
     * Returns Graph Store Protocol client.
     * 
     * @return GSP client
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }
    
    /**
     * Returns RDF input stream.
     * 
     * @return input stream
     */
    public InputStream getInputStream()
    {
        return is;
    }
    
    /**
     * Returns base URI.
     * 
     * @return base URI string
     */
    public String getBase()
    {
        return base;
    }
    
    /**
     * Returns the <code>CONSTRUCT</code> transformation query.
     * 
     * @return SPARQL query or null
     */
    public Query getQuery()
    {
        return query;
    }
    
    /**
     * Returns RDF language.
     * 
     * @return RDF lang
     */
    public Lang getLang()
    {
        return lang;
    }
    
    /**
     * Returns named graph URI.
     * 
     * @return graph URI string
     */
    public String getGraphURI()
    {
        return graphURI;
    }
    
}
