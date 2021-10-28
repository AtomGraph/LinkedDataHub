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
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.ext.MessageBodyWriter;
import javax.ws.rs.ext.Providers;
import nu.xom.Builder;
import nu.xom.Document;
import nu.xom.ParsingException;
import nu.xom.canonical.Canonicalizer;
import org.apache.commons.io.IOUtils;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.glassfish.jersey.server.ContainerRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that fixes XHTML content in RDF/POST payload.
 * <code>rdf:XMLLiteral</code> needs to be canonical XML, therefore we wrap the original XHTML into
 * a <code>&gt;div&gt;</code> element and canonicalize the document.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Priority(Priorities.ENTITY_CODER)
public class RDFPostCleanupFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(RDFPostCleanupFilter.class);

    @Context Providers providers;

    @Override
    public void filter(ContainerRequestContext context) throws IOException
    {
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.APPLICATION_FORM_URLENCODED_TYPE))
        {
            try (InputStream is = fixRDFPostStream(context.getEntityStream(), StandardCharsets.UTF_8))
            {
                // set re-serialized RDF/POST as request entity stream
                context.setEntityStream(is);
                // TO-DO: replace generic Form URL-encoded media type with RDF/POST
                // context.setMediaType(MediaType.APPLICATION_RDF_URLENCODED_TYPE);
            }
            catch (ParsingException ex)
            {
                throw new IOException(ex);
            }
        }
        
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
    
    public InputStream fixRDFPostStream(InputStream is, Charset charset) throws IOException, ParsingException
    {
        StringWriter writer = new StringWriter();
        IOUtils.copy(is, writer, charset);

        String formData = writer.toString();

        if (formData.startsWith(TokenizerRDFPost.RDF))
        {
            String charsetName = charset.name();
            String[] params = formData.split("&");
            List<String> keys = new ArrayList<>(), values = new ArrayList<>();

            // decode keys/values first
            for (String param : params)
            {
                String[] keyValue = param.split("=");

                try
                {
                    String key = URLDecoder.decode(keyValue[0], charsetName);
                    keys.add(key);

                    if (keyValue.length > 1) // value is present
                    {
                        String value = URLDecoder.decode(keyValue[1], charsetName);
                        values.add(value);
                    }
                    else values.add(null);
                }
                catch (UnsupportedEncodingException ex)
                {
                    if (log.isWarnEnabled()) log.warn("Unsupported encoding", ex);
                }
            }

            // encode again with fixed values
            String rdfPost = "";
            values = fixValues(keys, values, charsetName);

            for (int i = 0; i < keys.size(); i++)
            {
                String key = keys.get(i);
                String value = values.get(i);

                rdfPost += URLEncoder.encode(key, charsetName) + "=";
                if (value != null) rdfPost += URLEncoder.encode(value, charsetName);
                if (i + 1 < keys.size()) rdfPost += "&";
            }

            // set re-serialized RDF/POST as request entity stream
            return new ByteArrayInputStream(rdfPost.getBytes(charsetName));
        }
        
        return is;
    }
    
    
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
                        bodyPart.setValue(fixXHTML(xml, charsetName));
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
                        bodyPart.setValue(fixXHTML(xml, charsetName));
                    }
                }
            }
        }
        
        return multiPart;
    }
    
    /**
     * Wraps <code>XMLLiteral</code> values of <code>rdf:first</code> into <code>&lt;div&gt;</code> and canonicalizes the XML structure.
     * 
     * @param keys RDF/POST keys
     * @param values RDF/POST values
     * @param charsetName
     * @return fixed values
     * 
     * @throws ParsingException
     * @throws IOException 
     */
    public List<String> fixValues(List<String> keys, List<String> values, String charsetName) throws ParsingException, IOException
    {
        if (keys == null) throw new IllegalArgumentException("List<String> cannot be null");
        if (values == null) throw new IllegalArgumentException("List<String> cannot be null");

        for (int i = 0; i < keys.size(); i++)
        {
            // only fix XMLLiterals that are objects of rdf:first
            // in case of XHTML from WYMEditor, stmt.getLiteral().isWellFormedXML() == false at this point
            // we want to fix 2 cases (URL-decoded):
            
            // 1. ...pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#first&ol=value&lt=http://...XMLLiteral...
            if (i >= 1 && i + 1 < keys.size() && // check bounds
                keys.get(i - 1).equals(TokenizerRDFPost.URI_PRED) &&
                values.get(i - 1) != null && values.get(i - 1).equals(RDF.first.getURI()) &&
                keys.get(i).equals(TokenizerRDFPost.LITERAL_OBJ) &&
                values.get(i) != null &&
                keys.get(i + 1).equals(TokenizerRDFPost.TYPE)&&
                values.get(i + 1) != null && values.get(i + 1).equals(RDF.xmlLiteral.getURI()))
            {
                String xml = values.get(i);
                values.set(i, fixXHTML(xml, charsetName));
            }

            // 2. ...pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#first&lt=http://...XMLLiteral&ol=value...
            if (i >= 2 &&
                keys.get(i - 2).equals(TokenizerRDFPost.URI_PRED) &&
                values.get(i - 2) != null && values.get(i - 2).equals(RDF.first.getURI()) &&
                keys.get(i - 1).equals(TokenizerRDFPost.TYPE) &&
                values.get(i) != null &&
                values.get(i - 1) != null && values.get(i - 1).equals(RDF.xmlLiteral.getURI()) &&
                keys.get(i).equals(TokenizerRDFPost.LITERAL_OBJ))
            {
                String xml = values.get(i);
                values.set(i, fixXHTML(xml, charsetName));
            }
        }
        
        return values;
    }
    
    public String fixXHTML(String xhtml, String charsetName) throws IOException, ParsingException
    {
        if (xhtml == null) throw new IllegalArgumentException("XHTML String cannot be null");
        
        return canonicalizeXML("<div xmlns='http://www.w3.org/1999/xhtml'>" + xhtml + "</div>", charsetName);
    }
    
    public String canonicalizeXML(String xml, String charsetName) throws IOException, ParsingException
    {
        if (xml == null) throw new IllegalArgumentException("XML String cannot be null");
        if (charsetName == null) throw new IllegalArgumentException("Charset String cannot be null");

        try (ByteArrayInputStream bais = new ByteArrayInputStream(xml.getBytes(charsetName));
                ByteArrayOutputStream baos = new ByteArrayOutputStream())
        {
            Document xhtml = new Builder().build(bais);
            new Canonicalizer(baos).write(xhtml);
            return baos.toString(StandardCharsets.UTF_8.name());
        }
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
}
