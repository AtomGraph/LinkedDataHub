/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import static java.util.regex.Pattern.DOTALL;
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
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request interceptor that fixes XHTML content in SPARQL update payload.
  * <code>rdf:XMLLiteral</code> needs to be canonical XML, therefore we wrap the original XHTML into
 * a <code>&lt;div&gt;</code> element and canonicalize the document.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.ENTITY_CODER + 10)
public class UpdateRequestCleanupInterceptor implements ReaderInterceptor
{

    private static final Logger log = LoggerFactory.getLogger(UpdateRequestCleanupInterceptor.class);

    @Override
    public Object aroundReadFrom(ReaderInterceptorContext context) throws IOException, WebApplicationException
    {
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.APPLICATION_SPARQL_UPDATE_TYPE)) // so far this only happens in PATCH requests
        {
            StringWriter writer = new StringWriter();
            IOUtils.copy(context.getInputStream(), writer, StandardCharsets.UTF_8);

            String updateString = writer.toString();

            if (updateString.contains("<" + RDF.xmlLiteral.getURI() + ">"))
            {
                // enable DOTALL flag in order to match newlines: https://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#DOTALL
                Pattern pattern = Pattern.compile("\\\"(.*)\\\"\\^\\^<http:\\/\\/www\\.w3\\.org\\/1999\\/02\\/22-rdf-syntax-ns#XMLLiteral>", DOTALL);
                Matcher matcher = pattern.matcher(updateString);
                while (matcher.find())
                {
                    String xml = matcher.group(1);
                    try
                    {
                        xml = canonicalizeXML(wrapXHTML(xml), StandardCharsets.UTF_8.name());
                        String xmlLiteral = "\"\"\"" + xml + "\"\"\"^^<" + RDF.xmlLiteral.getURI() + ">";
                        updateString = matcher.replaceFirst(xmlLiteral);
                    }
                    catch (ParsingException ex)
                    {
                        throw new IOException(ex);
                    }
                }
            }
            
            context.setInputStream(new ByteArrayInputStream(updateString.getBytes(StandardCharsets.UTF_8))); // restore the request entity
        }
        
        return context.proceed();
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
