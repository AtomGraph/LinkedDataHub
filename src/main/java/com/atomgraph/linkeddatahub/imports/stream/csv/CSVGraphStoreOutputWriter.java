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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.function.Function;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * RDF stream writer.
 * A function that converts client response with CSV data to a stream of transformed RDF data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class CSVGraphStoreOutputWriter implements Function<Response, CSVGraphStoreOutput>
{

    private static final Logger log = LoggerFactory.getLogger(CSVGraphStoreOutputWriter.class);

    private final Service service, adminService;
    private final GraphStoreClient gsc;
    private final String baseURI;
    private final Query query;
    private final char delimiter;
    
    /**
     * Constructs output writer.
     * 
     * @param service SPARQL service of the application
     * @param adminService SPARQL service of the admin application
     * @param gsc Graph Store client
     * @param baseURI base URI
     * @param query transformation query
     * @param delimiter CSV delimiter
     */
    public CSVGraphStoreOutputWriter(Service service, Service adminService, GraphStoreClient gsc,  String baseURI, Query query, char delimiter)
    {
        this.service = service;
        this.adminService = adminService;
        this.gsc = gsc;
        this.baseURI = baseURI;
        this.query = query;
        this.delimiter = delimiter;
    }
    
    @Override
    public CSVGraphStoreOutput apply(Response csvInput)
    {
        if (csvInput == null) throw new IllegalArgumentException("Response cannot be null");

        try
        {
            // buffer the CSV in a temp file before transforming it
            File tempFile = File.createTempFile(UUID.randomUUID().toString(), "tmp");
            try (csvInput; InputStream csvIs = csvInput.readEntity(InputStream.class); OutputStream output = new FileOutputStream(tempFile))
            {
                csvIs.transferTo(output);
            }
            
            try (InputStream fis = new FileInputStream(tempFile); Reader reader = new InputStreamReader(fis, StandardCharsets.UTF_8))
            {
                CSVGraphStoreOutput output = new CSVGraphStoreOutput(getService(), getAdminService(), getGraphStoreClient(), getBaseURI(), reader, getQuery(), getDelimiter(), null);
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
            if (log.isErrorEnabled()) log.error("Error reading CSV InputStream: {}", ex);
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
     * Returns the Graph Store client.
     * 
     * @return client object
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return gsc;
    }
    
    /**
     * Returns base URI.
     * 
     * @return URI string
     */
    public String getBaseURI()
    {
        return baseURI;
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
     * Returns the CSV delimiter.
     * 
     * @return the delimiting character
     */
    public char getDelimiter()
    {
        return delimiter;
    }
    
}
