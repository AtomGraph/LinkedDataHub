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
package com.atomgraph.linkeddatahub.server.io;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import com.univocity.parsers.common.processor.RowListProcessor;
import com.univocity.parsers.csv.CsvParser;
import com.univocity.parsers.csv.CsvParserSettings;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.List;
import javax.ws.rs.Consumes;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.MessageBodyReader;
import javax.ws.rs.ext.Provider;
import javax.ws.rs.ext.Providers;
import javax.ws.rs.core.Context;
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * JAX-RS provider that reads RDF model from CSV files.
 * Cannot be used in Client because it depends on UriInfo to resolve relative URIs against.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
@Deprecated
@Consumes({"text/csv", "application/vnd.ms-excel"})
public class GenericCSVReader implements MessageBodyReader<Model>
{
    private static final Logger log = LoggerFactory.getLogger(GenericCSVReader.class);

    private String baseURI;
    
    @Context UriInfo uriInfo;
    @Context Providers providers;
    
    public GenericCSVReader()
    {
    }
    
    public GenericCSVReader(String baseURI)
    {
        this.baseURI = baseURI;
    }
    
    @Override
    public boolean isReadable(Class<?> type, Type type1, Annotation[] antns, MediaType mt)
    {
        return type == Model.class; // && mt.isCompatible(new MediaType("text", "csv"));
    }
    
    @Override
    public Model readFrom(Class<Model> type, Type type1, Annotation[] antns, MediaType mt, MultivaluedMap<String, String> mm, InputStream in) throws IOException, WebApplicationException
    {
        CsvParserSettings parserSettings = new CsvParserSettings();
        parserSettings.setLineSeparatorDetectionEnabled(true);
        RowListProcessor rowProcessor = new RowListProcessor();
        parserSettings.setRowProcessor(rowProcessor);
        parserSettings.setHeaderExtractionEnabled(true);
        parserSettings.setDelimiterDetectionEnabled(true);

        Model model = ModelFactory.createDefaultModel();
        CsvParser parser = new CsvParser(parserSettings);
        try (InputStreamReader isr = new InputStreamReader(in, StandardCharsets.UTF_8))
        {
            parser.parse(isr);
        }
        
        String[] headers = rowProcessor.getHeaders();
        List<String[]> rows = rowProcessor.getRows();
    
        Iterator<String[]> rowIt = rows.iterator();
        while (rowIt.hasNext())
        {
            String[] row = rowIt.next();
            Resource resource = model.createResource();
            int cellNo = 0;
            for (String cell : row)
            {
                if (cell != null && headers[cellNo] != null)
                {
                    String fragmentId = UriComponent.contextualEncode(headers[cellNo], UriComponent.Type.FRAGMENT);
                    Property property = model.createProperty(getBaseURI(), "#" + fragmentId);
                    resource.addProperty(property, cell);
                }
                cellNo++;
            }
        }
        
        //model.setBaseURI()?
        return model;
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
    public String getBaseURI()
    {
        if (baseURI != null) return baseURI;  // in case GenericCSVReader was constructed directly with baseURI
        
        return getUriInfo().getRequestUri().toString();
    }
    
    public UriInfo getUriInfo()
    {
	return uriInfo;
    }
    
}
