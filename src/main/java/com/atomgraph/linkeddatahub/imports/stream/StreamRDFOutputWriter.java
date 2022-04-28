/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.core.MediaType;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;
import java.util.function.Function;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * RDF stream writer.
 * A function that converts client response with RDF data to a stream of (optionally transformed) RDF data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class StreamRDFOutputWriter implements Function<Response, RDFGraphStoreOutput>
{
    
    private static final Logger log = LoggerFactory.getLogger(StreamRDFOutputWriter.class);

    private final Service service, adminService;
    private final GraphStoreClient graphStoreClient;
    private final String baseURI, graphURI;
    private final Query query;

    /**
     * Constructs output writer.
     * 
     * @param service SPARQL service of the application
     * @param adminService SPARQL service of the admin application
     * @param graphStoreClient GSP client
     * @param baseURI base URI
     * @param query transformation query or null
     * @param graphURI target graph URI
     */
    public StreamRDFOutputWriter(Service service, Service adminService, GraphStoreClient graphStoreClient, String baseURI, Query query, String graphURI)
    {
        this.service = service;
        this.adminService = adminService;
        this.graphStoreClient = graphStoreClient;
        this.baseURI = baseURI;
        this.query = query;
        this.graphURI = graphURI;
    }

    @Override
    public RDFGraphStoreOutput apply(Response rdfInput)
    {
        if (rdfInput == null) throw new IllegalArgumentException("Response cannot be null");
        
        try
        {
            if (!rdfInput.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL)) throw new ImportException("Could not load RDF file", null);
            
            // buffer the RDF in a temp file before transforming it
            File tempFile = File.createTempFile(UUID.randomUUID().toString(), "tmp");
            try (rdfInput; InputStream rdfIs = rdfInput.readEntity(InputStream.class); OutputStream output = new FileOutputStream(tempFile))
            {
                rdfIs.transferTo(output);
            }

            try (InputStream fis = new FileInputStream(tempFile))
            {
                MediaType mediaType = new MediaType(rdfInput.getMediaType().getType(), rdfInput.getMediaType().getSubtype()); // discard charset param
                Lang lang = RDFLanguages.contentTypeToLang(mediaType.toString()); // convert media type to RDF language
                if (lang == null) throw new BadRequestException("Content type '" + mediaType + "' is not an RDF media type");

                RDFGraphStoreOutput output = new RDFGraphStoreOutput(getService(), getAdminService(), getGraphStoreClient(), fis, getBaseURI(), getQuery(), lang, getGraphURI());
                output.write();
                return output;
            }
            finally
            {
                tempFile.delete();
            }
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading RDF InputStream: {}", ex);
            throw new WebApplicationException(ex);
        }
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
     * Returns the Graph Store Protocol client.
     * 
     * @return GSP client
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }
    
    /**
     * Returns the base URI.
     * 
     * @return base URI string
     */
    public String getBaseURI()
    {
        return baseURI;
    }
    
    /**
     * Returns the transformation query.
     * 
     * @return SPARQL query or null
     */
    public Query getQuery()
    {
        return query;
    }
    
    /**
     * Returns the target graph URI.
     * 
     * @return named graph URI
     */
    public String getGraphURI()
    {
        return graphURI;
    }
    
}