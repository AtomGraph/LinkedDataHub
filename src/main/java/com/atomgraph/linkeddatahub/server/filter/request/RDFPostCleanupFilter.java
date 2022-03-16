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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.core.MediaType;
import com.atomgraph.core.riot.lang.TokenizerRDFPost;
import com.atomgraph.linkeddatahub.server.interceptor.RDFPostCleanupInterceptor;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.ext.MessageBodyWriter;
import javax.ws.rs.ext.Providers;
import nu.xom.ParsingException;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.glassfish.jersey.server.ContainerRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that fixes XHTML content in RDF/POST payload.
 * <code>rdf:XMLLiteral</code> needs to be canonical XML, therefore we wrap the original XHTML into
 * a <code>&lt;div&gt;</code> element and canonicalize the document.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.interceptor.RDFPostCleanupInterceptor
 */
@Priority(Priorities.ENTITY_CODER)
public class RDFPostCleanupFilter extends RDFPostCleanupInterceptor implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(RDFPostCleanupFilter.class);

    @Context Providers providers;

    @Override
    public void filter(ContainerRequestContext context) throws IOException
    {
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.MULTIPART_FORM_DATA_TYPE))
        {
            try
            {
                ContainerRequest request = (ContainerRequest)context;
                FormDataMultiPart multiPart = request.readEntity(FormDataMultiPart.class);
                fixRDFPostMultiPart(multiPart, StandardCharsets.UTF_8);

                MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();
                request.getHeaders().entrySet().stream().forEach(entry -> entry.getValue().forEach(value -> headers.add(entry.getKey(), value)));
                ByteArrayOutputStream baos =  new ByteArrayOutputStream();
                
                MessageBodyWriter<FormDataMultiPart> writer = getProviders().getMessageBodyWriter(FormDataMultiPart.class, null, null, request.getMediaType());
                writer.writeTo(multiPart, FormDataMultiPart.class, null, null, request.getMediaType(), headers, baos);
                
                request.setEntityStream(new ByteArrayInputStream(baos.toByteArray()));
            }
            catch (ParsingException ex)
            {
                throw new IOException(ex);
            }
        }
    }
    
    /**
     * Canonicalizes XHTML literals within multipart RDF/POST body.
     * 
     * @param multiPart multipart RDF/POST form data
     * @param charset charset name
     * @return fixed mutipart form data
     * @throws IOException I/O error
     * @throws ParsingException XML parsing error
     */
    public FormDataMultiPart fixRDFPostMultiPart(FormDataMultiPart multiPart, Charset charset) throws IOException, ParsingException
    {
        String charsetName = charset.name();
        for (int i = 0; i < multiPart.getBodyParts().size(); i++)
        {
            FormDataBodyPart bodyPart = (FormDataBodyPart)multiPart.getBodyParts().get(i);

            // it's a file (if the filename is not empty)
            if (bodyPart.getContentDisposition().getFileName() != null &&
                    !bodyPart.getContentDisposition().getFileName().isEmpty())
            {
                if (log.isDebugEnabled()) log.debug("FormDataBodyPart name: {} value: {}", bodyPart.getName(), bodyPart.getContentDisposition().getFileName());
            }
            else
            {
                if (bodyPart.isSimple() && !bodyPart.getValue().isEmpty())
                {
                    if (log.isDebugEnabled()) log.debug("FormDataBodyPart name: {} value: {}", bodyPart.getName(), bodyPart.getValue());
//                    keys.add(bodyPart.getName());
//                    values.add(bodyPart.getValue());

                    // only fix XMLLiterals that are objects of rdf:first
                    // in case of XHTML from WYMEditor, stmt.getLiteral().isWellFormedXML() == false at this point
                    // we want to fix 2 cases (URL-decoded):

                    // 1. ...pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#first&ol=value&lt=http://...XMLLiteral...
                    if (i >= 1 && i + 1 < multiPart.getBodyParts().size() && // check bounds
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getName().equals(TokenizerRDFPost.URI_PRED) &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getValue() != null &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getValue().equals(RDF.first.getURI()) &&
                        bodyPart.getName().equals(TokenizerRDFPost.LITERAL_OBJ) &&
                        bodyPart.getValue() != null &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i + 1)).getName().equals(TokenizerRDFPost.TYPE) &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i + 1)).getValue() != null &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i + 1)).getValue().equals(RDF.xmlLiteral.getURI()))
                    {
                        String xml = bodyPart.getValue();
                        bodyPart.setValue(canonicalizeXML(wrapXHTML(xml), charsetName));
                    }

                    // 2. ...pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#first&lt=http://...XMLLiteral&ol=value...
                    if (i >= 2 &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 2)).getName().equals(TokenizerRDFPost.URI_PRED) &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 2)).getValue() != null &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 2)).getValue().equals(RDF.first.getURI()) &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getName().equals(TokenizerRDFPost.TYPE) &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getValue() != null &&
                        ((FormDataBodyPart)multiPart.getBodyParts().get(i - 1)).getValue().equals(RDF.xmlLiteral.getURI()) &&
                        bodyPart.getName().equals(TokenizerRDFPost.LITERAL_OBJ) &&
                        bodyPart.getValue() != null)
                    {
                        String xml = bodyPart.getValue();
                        bodyPart.setValue(canonicalizeXML(wrapXHTML(xml), charsetName));
                    }
                }
            }
        }
        
        return multiPart;
    }
    
    /**
     * Returns registry of JAX-RS providers.
     * 
     * @return JAX-RS provider registry
     */
    public Providers getProviders()
    {
        return providers;
    }
    
}
