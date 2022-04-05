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
package com.atomgraph.linkeddatahub.server.interceptor;

import com.atomgraph.core.MediaType;
import com.atomgraph.core.riot.lang.TokenizerRDFPost;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.ext.ReaderInterceptor;
import javax.ws.rs.ext.ReaderInterceptorContext;
import nu.xom.Builder;
import nu.xom.Document;
import nu.xom.ParsingException;
import nu.xom.canonical.Canonicalizer;
import org.apache.commons.io.IOUtils;
import org.apache.jena.riot.RiotException;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request interceptor that fixes XHTML content in RDF/POST payload.
 * <code>rdf:XMLLiteral</code> needs to be canonical XML, therefore we wrap the original XHTML into
 * a <code>&lt;div&gt;</code> element and canonicalize the document.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.filter.request.RDFPostCleanupFilter
 */
@Priority(Priorities.ENTITY_CODER)
public class RDFPostCleanupInterceptor implements ReaderInterceptor
{

    private static final Logger log = LoggerFactory.getLogger(RDFPostCleanupInterceptor.class);

    @Override
    public Object aroundReadFrom(ReaderInterceptorContext context) throws IOException, WebApplicationException
    {
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.APPLICATION_RDF_URLENCODED_TYPE))
        {
            StringWriter writer = new StringWriter();
            IOUtils.copy(context.getInputStream(), writer, StandardCharsets.UTF_8);
            
            String formData = writer.toString();
            
            if (!formData.startsWith(TokenizerRDFPost.RDF)) throw new RiotException("Could not parse RDF/POST");

            String charsetName = "UTF-8";
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
                    throw new RiotException(ex);
                }
            }

            // encode again with fixed values
            try
            {
                String rdfPost = "";
                values = fixValues(keys, values, charsetName);

                for (int j = 0; j < keys.size(); j++)
                {
                    String key = keys.get(j);
                    String value = values.get(j);

                    rdfPost += URLEncoder.encode(key, charsetName) + "=";
                    if (value != null) rdfPost += URLEncoder.encode(value, charsetName);
                    if (j + 1 < keys.size()) rdfPost += "&";
                }

                // set re-serialized RDF/POST as request entity stream
                context.setInputStream(new ByteArrayInputStream(rdfPost.getBytes(charsetName)));
            }
            catch (ParsingException | IOException ex)
            {
                throw new RiotException(ex);
            }
        }
        
        return context.proceed();
    }
    
    /**
     * Wraps <code>XMLLiteral</code> values of <code>rdf:first</code> into <code>&lt;div&gt;</code> and canonicalizes the XML structure.
     * 
     * @param keys RDF/POST keys
     * @param values RDF/POST values
     * @param charsetName charset name
     * @return fixed values
     * 
     * @throws ParsingException parsing error
     * @throws IOException I/O error
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
                keys.get(i + 1).equals(TokenizerRDFPost.TYPE)&&
                values.get(i + 1) != null && values.get(i + 1).equals(RDF.xmlLiteral.getURI()) &&
                values.get(i) != null)
            {
                String xml = values.get(i);
                values.set(i, canonicalizeXML(wrapXHTML(xml), charsetName));
            }

            // 2. ...pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#first&lt=http://...XMLLiteral&ol=value...
            if (i >= 2 &&
                keys.get(i - 2).equals(TokenizerRDFPost.URI_PRED) &&
                values.get(i - 2) != null && values.get(i - 2).equals(RDF.first.getURI()) &&
                keys.get(i - 1).equals(TokenizerRDFPost.TYPE) &&
                values.get(i - 1) != null && values.get(i - 1).equals(RDF.xmlLiteral.getURI()) &&
                keys.get(i).equals(TokenizerRDFPost.LITERAL_OBJ) &&
                values.get(i) != null)
            {
                String xml = values.get(i);
                values.set(i, canonicalizeXML(wrapXHTML(xml), charsetName));
            }
        }
        
        return values;
    }
    
    /**
     * Wraps XHTML content string into a <code>&lt;div&gt;</code> element.
     * 
     * @param xhtml XHTML string
     * @return wrapped XHTML string
     */
    public String wrapXHTML(String xhtml)
    {
        if (xhtml == null) throw new IllegalArgumentException("XHTML String cannot be null");
        
        return "<div xmlns='http://www.w3.org/1999/xhtml'>" + xhtml + "</div>";
    }
    
    /**
     * Canonicalizes XML string.
     * 
     * @param xml XML string
     * @param charsetName charset name
     * @return canonicalized XML string
     * @throws IOException I/O exception
     * @throws ParsingException XML parsing error
     * @see <a href="https://www.w3.org/TR/xml-c14n11/">Canonical XML Version 1.1</a>
     */
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
    
}
