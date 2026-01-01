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

import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import java.io.InputStream;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.net.URI;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Reads RDF from input stream and writes it into a named graph.
 * If a transformation query is provided, the input is transformed before writing.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class RDFGraphStoreOutput
{

    private static final Logger log = LoggerFactory.getLogger(RDFGraphStoreOutput.class);

    private final Service service, adminService;
    private final GraphStoreClient gsc;
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
     * @param gsc Graph Store client for RDF results
     * @param is RDF input stream
     * @param base base URI
     * @param query <code>CONSTRUCT</code> transformation query or null
     * @param lang RDF language
     * @param graphURI named graph URI
     */
    public RDFGraphStoreOutput(Service service, Service adminService, GraphStoreClient gsc, InputStream is, String base, Query query, Lang lang, String graphURI)
    {
        this.service = service;
        this.adminService = adminService;
        this.gsc = gsc;
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
     * The default graph output is ignored.
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
                        Model namedModel = dataset.getNamedModel(graphUri);
                        
                        if (!namedModel.isEmpty())
                        {
                            // <code>If-None-Match</code> used with the <code>*</code> value can be used to save a file only if it does not already exist,
                            // guaranteeing that the upload won't accidentally overwrite another upload and lose the data of the previous <code>PUT</code>
                            // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match
                            MultivaluedMap<String, Object> headers = new MultivaluedHashMap();
                            headers.putSingle(HttpHeaders.IF_NONE_MATCH, "*");
                            
                            try (Response putResponse = getGraphStoreClient().put(URI.create(graphUri), Entity.entity(namedModel, getGraphStoreClient().getDefaultMediaType()), new jakarta.ws.rs.core.MediaType[]{}, headers))
                            {
                                if (putResponse.getStatusInfo().equals(Response.Status.PRECONDITION_FAILED))
                                {
                                    try (Response postResponse = getGraphStoreClient().post(URI.create(graphUri), namedModel))
                                    {                                
                                        if (!postResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                                        {
                                            if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using PUT. Status code: {}", graphUri, postResponse.getStatus());
                                            throw new ImportException(new IOException("RDF document with URI <" + graphUri + "> could not be successfully created using PUT. Status code: " + postResponse.getStatus()));
                                        }
                                    }
                                }
                                else
                                {
                                    if (!putResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                                    {
                                        if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using PUT. Status code: {}", graphUri, putResponse.getStatus());
                                        throw new ImportException(new IOException("RDF document with URI <" + graphUri + "> could not be successfully created using PUT. Status code: " + putResponse.getStatus()));
                                    }
                                }
                            }
                        
                            // purge cache entries that include the graph URI
                            if (getService().getBackendProxy() != null) ban(getService().getClient(), getService().getBackendProxy(), graphUri).close();
                            if (getAdminService() != null && getAdminService().getBackendProxy() != null) ban(getAdminService().getClient(), getAdminService().getBackendProxy(), graphUri).close();
                        }
                    }
                );
            }
        }
        else
        {
            if (getGraphURI() == null) throw new IllegalStateException("Neither RDFImport query nor graph name is specified");
            
            // <code>If-None-Match</code> used with the <code>*</code> value can be used to save a file only if it does not already exist,
            // guaranteeing that the upload won't accidentally overwrite another upload and lose the data of the previous <code>PUT</code>
            // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match
            MultivaluedMap<String, Object> headers = new MultivaluedHashMap();
            headers.putSingle(HttpHeaders.IF_NONE_MATCH, "*");

            try (Response putResponse = getGraphStoreClient().put(URI.create(getGraphURI()), Entity.entity(model, getGraphStoreClient().getDefaultMediaType()), new jakarta.ws.rs.core.MediaType[]{},  headers))
            {
                if (putResponse.getStatusInfo().equals(Response.Status.PRECONDITION_FAILED))
                {
                    try (Response postResponse = getGraphStoreClient().post(URI.create(getGraphURI()), model))
                    {
                        if (!postResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                        {
                            if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using PUT. Status code: {}", getGraphURI(), postResponse.getStatus());
                            throw new ImportException(new IOException("RDF document with URI <" + getGraphURI() + "> could not be successfully created using PUT. Status code: " + postResponse.getStatus()));
                        }
                    }
                }
                else
                {
                    if (!putResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("RDF document with URI <{}> could not be successfully created using PUT. Status code: {}", getGraphURI(), putResponse.getStatus());
                        throw new ImportException(new IOException("RDF document with URI <" + getGraphURI() + "> could not be successfully created using PUT. Status code: " + putResponse.getStatus()));
                    }
                }
            }
                
            // purge cache entries that include the graph URI
            if (getService().getBackendProxy() != null) ban(getService().getClient(), getService().getBackendProxy(), getGraphURI()).close();
            if (getAdminService() != null && getAdminService().getBackendProxy() != null) ban(getAdminService().getClient(), getAdminService().getBackendProxy(), getGraphURI()).close();
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
     * Returns Graph Store client.
     * 
     * @return client object
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return gsc;
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
