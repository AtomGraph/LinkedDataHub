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
import java.io.IOException;
import java.io.InputStream;
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

    private final GraphStoreClient graphStoreClient;
    private final String baseURI, graphURI;
    private final Query query;

    public StreamRDFOutputWriter(GraphStoreClient graphStoreClient, String baseURI, Query query, String graphURI)
    {
        this.graphStoreClient = graphStoreClient;
        this.baseURI = baseURI;
        this.query = query;
        this.graphURI = graphURI;
    }

    @Override
    public RDFGraphStoreOutput apply(Response input)
    {
        if (input == null) throw new IllegalArgumentException("Response cannot be null");
        
        try (input; InputStream is = input.readEntity(InputStream.class))
        {
            MediaType mediaType = new MediaType(input.getMediaType().getType(), input.getMediaType().getSubtype()); // discard charset param
            Lang lang = RDFLanguages.contentTypeToLang(mediaType.toString()); // convert media type to RDF language
            if (lang == null) throw new BadRequestException("Content type '" + mediaType + "' is not an RDF media type");

            RDFGraphStoreOutput output = new RDFGraphStoreOutput(getGraphStoreClient(), is, getBaseURI(), getQuery(), lang, getGraphURI());
            output.write();
            return output;
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading RDF InputStream: {}", ex);
            throw new WebApplicationException(ex);
        }
    }
    
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }
    
    public String getBaseURI()
    {
        return baseURI;
    }
       
    public Query getQuery()
    {
        return query;
    }
    
    public String getGraphURI()
    {
        return graphURI;
    }
    
}