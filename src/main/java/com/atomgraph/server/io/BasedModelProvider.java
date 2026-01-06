/*
 * Copyright 2017 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.server.io;

import com.atomgraph.core.io.ModelProvider;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.shared.NoReaderForLangException;
import org.apache.jena.shared.NoWriterForLangException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A provider that reads/writes model and resolves relative URIs against request base URI.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class BasedModelProvider extends ModelProvider
{
    
    private static final Logger log = LoggerFactory.getLogger(BasedModelProvider.class);

    @Context UriInfo uriInfo;

    @Override
    public Model readFrom(Class<Model> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, String> httpHeaders, InputStream entityStream) throws IOException
    {
        if (log.isTraceEnabled()) log.trace("Reading Model with HTTP headers: {} MediaType: {}", httpHeaders, mediaType);
        
        Model model = ModelFactory.createDefaultModel();

        MediaType formatType = new MediaType(mediaType.getType(), mediaType.getSubtype()); // discard charset param
        Lang lang = RDFLanguages.contentTypeToLang(formatType.toString());
        if (lang == null)
        {
            if (log.isErrorEnabled()) log.error("MediaType '{}' not supported by Jena", formatType);
            throw new NoReaderForLangException("MediaType not supported: " + formatType);
        }
        if (log.isDebugEnabled()) log.debug("RDF language used to read Model: {}", lang);
        
        return read(model, entityStream, lang, getUriInfo().getAbsolutePath().toString());
    }
    
    @Override
    public void writeTo(Model model, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, Object> httpHeaders, OutputStream entityStream) throws IOException
    {
        if (log.isTraceEnabled()) log.trace("Writing Model with HTTP headers: {} MediaType: {}", httpHeaders, mediaType);

        MediaType formatType = new MediaType(mediaType.getType(), mediaType.getSubtype()); // discard charset param
        Lang lang = RDFLanguages.contentTypeToLang(formatType.toString());
        if (lang == null)
        {
            if (log.isErrorEnabled()) log.error("MediaType '{}' not supported by Jena", formatType);
            throw new NoWriterForLangException("MediaType not supported: " + formatType);
        }
        if (log.isDebugEnabled()) log.debug("RDF language used to read Model: {}", lang);
        
        write(model, entityStream, lang, getUriInfo().getAbsolutePath().toString());
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

}
