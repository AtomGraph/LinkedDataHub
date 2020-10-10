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

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaType;
import com.atomgraph.linkeddatahub.exception.ImportException;
import com.atomgraph.linkeddatahub.imports.StreamRDFOutput;
import com.atomgraph.linkeddatahub.imports.csv.stream.CSVStreamRDFOutputWriter;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.function.Function;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class StreamRDFOutputWriter implements Function<Response, StreamRDFOutput>
{
    
    private static final Logger log = LoggerFactory.getLogger(CSVStreamRDFOutputWriter.class);

    private final String uri;
    private final DataManager dataManager;
    private final String baseURI;
    private final Query query;

    public StreamRDFOutputWriter(String uri, DataManager dataManager, String baseURI, Query query)
    {
        this.uri = uri;
        this.dataManager = dataManager;
        this.baseURI = baseURI;
        this.query = query;
    }

    @Override
    public StreamRDFOutput apply(Response input)
    {
        if (input == null) throw new IllegalArgumentException("Model cannot be null");
        
        try
        {
            try (InputStream is = input.readEntity(InputStream.class))
            {
                MediaType mediaType = new MediaType(input.getMediaType().getType(), input.getMediaType().getSubtype()); // discard charset param
                Lang lang = RDFLanguages.contentTypeToLang(mediaType.toString()); // convert media type to RDF language
                if (lang == null) throw new IllegalStateException("Content type '" + mediaType + "' is not an RDF media type");
                
                StreamRDFOutput rdfOutput = new StreamRDFOutput(is, getBaseURI(), getQuery(), lang);

                try (Response cr = getDataManager().getEndpoint(URI.create(getURI())).
                    request(MediaType.TEXT_NTRIPLES). // could be all RDF formats - we just want to avoid XHTML response
                    post(Entity.entity(rdfOutput, MediaType.TEXT_NTRIPLES)))
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
            if (log.isErrorEnabled()) log.error("Error reading RDF InputStream: {}", ex);
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
    
}