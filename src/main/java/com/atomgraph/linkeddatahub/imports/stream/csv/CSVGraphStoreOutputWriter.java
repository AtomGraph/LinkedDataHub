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

import com.atomgraph.core.client.GraphStoreClient;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.function.Function;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
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

    private final GraphStoreClient graphStoreClient;
    private final String baseURI;
    private final Query query;
    private final char delimiter;
    
    /**
     * Constructs output writer.
     * 
     * @param graphStoreClient GSP client
     * @param baseURI base URI
     * @param query transformation query
     * @param delimiter CSV delimiter
     */
    public CSVGraphStoreOutputWriter(GraphStoreClient graphStoreClient, String baseURI, Query query, char delimiter)
    {
        this.graphStoreClient = graphStoreClient;
        this.baseURI = baseURI;
        this.query = query;
        this.delimiter = delimiter;
    }
    
    @Override
    public CSVGraphStoreOutput apply(Response csvInput)
    {
        if (csvInput == null) throw new IllegalArgumentException("Response cannot be null");
        
        try (csvInput; InputStream is = csvInput.readEntity(InputStream.class); Reader reader = new InputStreamReader(is, StandardCharsets.UTF_8))
        {
            CSVGraphStoreOutput output = new CSVGraphStoreOutput(getGraphStoreClient(), reader, getBaseURI(), getQuery(), getDelimiter(), null);
            output.write();
            return output;
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading CSV InputStream: {}", ex);
            throw new WebApplicationException(ex);
        }
    }

    /**
     * Returns the Graph Store Protocol client.
     * 
     * @return client
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
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
