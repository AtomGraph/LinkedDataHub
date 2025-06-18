/*
 * Copyright 2023 Martynas Jusevičius <martynas@atomgraph.com>.
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
package com.atomgraph.linkeddatahub.writer;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import jakarta.inject.Singleton;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.MessageBodyWriter;
import jakarta.ws.rs.ext.Provider;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.util.Arrays;
import javax.xml.transform.TransformerException;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.http.HttpHeaders;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.query.ResultSetFormatter;
import org.apache.jena.query.ResultSetRewindable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * XSLT-based message body writer for SPARQL result sets.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Provider
@Singleton
@Produces({MediaType.TEXT_HTML + ";charset=UTF-8", MediaType.APPLICATION_XHTML_XML + ";charset=UTF-8"})
public class ResultSetXSLTWriter extends XSLTWriterBase implements MessageBodyWriter<ResultSetRewindable>
{

    private static final Logger log = LoggerFactory.getLogger(ResultSetXSLTWriter.class);

    /**
     * Constructs XSLT writer.
     * 
     * @param xsltExec compiled XSLT stylesheet
     * @param ontModelSpec ontology specification
     * @param dataManager RDF data manager
     * @param messageDigest message digest
     */
    public ResultSetXSLTWriter(XsltExecutable xsltExec, OntModelSpec ontModelSpec, DataManager dataManager, MessageDigest messageDigest)
    {
        super(xsltExec, ontModelSpec, dataManager, messageDigest);
    }

    @Override
    public boolean isWriteable(Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType)
    {
        return (ResultSetRewindable.class.isAssignableFrom(type));
    }

    @Override
    public void writeTo(ResultSetRewindable results, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, Object> headerMap, OutputStream entityStream) throws IOException, WebApplicationException
    {
        if (log.isTraceEnabled()) log.trace("Writing ResultSet with HTTP headers: {} MediaType: {}", headerMap, mediaType);

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream())
        {
            // authenticated agents get a different HTML representation and therefore a different entity tag
            if (headerMap.containsKey(HttpHeaders.ETAG) && headerMap.getFirst(HttpHeaders.ETAG) instanceof EntityTag && getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                EntityTag eTag = (EntityTag)headerMap.getFirst(HttpHeaders.ETAG);
                BigInteger eTagHash = new BigInteger(eTag.getValue(), 16);
                Agent agent = (Agent)getSecurityContext().getUserPrincipal();
                eTagHash = eTagHash.add(BigInteger.valueOf(agent.hashCode()));
                headerMap.replace(HttpHeaders.ETAG, Arrays.asList(new EntityTag(eTagHash.toString(16))));
            }

            ResultSetFormatter.outputAsXML(baos, results);
  
            transform(baos, mediaType, headerMap, entityStream);
        }
        catch (TransformerException | SaxonApiException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT transformation failed", ex);
            throw new WebApplicationException(ex, Response.Status.INTERNAL_SERVER_ERROR); // TO-DO: make Mapper
        }
    }
    
}
