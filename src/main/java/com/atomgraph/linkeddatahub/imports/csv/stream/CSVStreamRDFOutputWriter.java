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
package com.atomgraph.linkeddatahub.imports.csv.stream;

import com.atomgraph.core.MediaType;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.function.Function;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * RDF stream writer.
 * A function that converts client response with CSV data to a stream of transformed RDF data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class CSVStreamRDFOutputWriter implements Function<Response, CSVStreamRDFOutput>
{

    private static final Logger log = LoggerFactory.getLogger(CSVStreamRDFOutputWriter.class);

    private final String uri;
    private final DataManager dataManager;
    private final String baseURI;
    private final Query query;
    private final char delimiter;
    
    public CSVStreamRDFOutputWriter(String uri, DataManager dataManager, String baseURI, Query query, char delimiter)
    {
        this.uri = uri;
        this.dataManager = dataManager;
        this.baseURI = baseURI;
        this.query = query;
        this.delimiter = delimiter;
    }
    
    @Override
    public CSVStreamRDFOutput apply(Response input)
    {
        if (input == null) throw new IllegalArgumentException("Model cannot be null");
        
        try
        {
            try (InputStream is = input.readEntity(InputStream.class))
            {
                CSVStreamRDFOutput rdfOutput = new CSVStreamRDFOutput(new InputStreamReader(is, StandardCharsets.UTF_8), getBaseURI(), getQuery(), getDelimiter());

                try (Response cr = getDataManager().getEndpoint(URI.create(getURI())).
                    request(MediaType.APPLICATION_NTRIPLES). // could be all RDF formats - we just want to avoid XHTML response
                    post(Entity.entity(rdfOutput, MediaType.APPLICATION_NTRIPLES)))
                {
                    if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        //if (log.isErrorEnabled()) log.error("Could not write Import into container. Response: {}", cr);
                        throw new ImportException(cr.toString(), cr.readEntity(Model.class));
                    }

                    return rdfOutput;
                }
            }
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading CSV InputStream: {}", ex);
            throw new WebApplicationException(ex);
        }
        finally
        {
            input.close(); // close response
        }
    }

    public String getURI()
    {
        return uri;
    }

    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    public String getBaseURI()
    {
        return baseURI;
    }
       
    public Query getQuery()
    {
        return query;
    }
    
    public char getDelimiter()
    {
        return delimiter;
    }
    
}
