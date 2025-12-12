/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.filter;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import com.atomgraph.core.exception.BadGatewayException;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.client.ClientResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmValue;
import net.sf.saxon.s9api.Xslt30Transformer;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract client filter that implements GRDDL pattern for JSON-based web services.
 * Redirects original URLs to JSON API endpoints and transforms JSON responses to RDF using XSLT 3.0.
 * 
 * @see <a href="https://www.w3.org/TR/grddl/">Gleaning Resource Descriptions from Dialects of Languages (GRDDL)</a>
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class JSONGRDDLFilter implements ClientRequestFilter, ClientResponseFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(JSONGRDDLFilter.class);
    
    private final XsltExecutable xsltExecutable;
    
    /**
     * Constructs GRDDL filter with XSLT compiler and stylesheet path.
     * 
     * @param xsltCompiler XSLT compiler
     * @param stylesheetPath classpath resource path to XSLT stylesheet
     * @throws SaxonApiException if stylesheet compilation fails
     */
    public JSONGRDDLFilter(XsltCompiler xsltCompiler, String stylesheetPath) throws SaxonApiException
    {
        if (xsltCompiler == null) throw new IllegalArgumentException("XsltCompiler cannot be null");
        if (stylesheetPath == null) throw new IllegalArgumentException("Stylesheet path cannot be null");
        
        Source stylesheetSource = new StreamSource(getClass().getResourceAsStream(stylesheetPath));
        this.xsltExecutable = xsltCompiler.compile(stylesheetSource);
        
        if (log.isDebugEnabled()) log.debug("Compiled GRDDL stylesheet from {} for {}", stylesheetPath, getClass().getSimpleName());
    }
    
    private static final String ORIGINAL_URI_PROPERTY = "com.atomgraph.linkeddatahub.originalRequestURI";
    
    @Override
    public void filter(ClientRequestContext requestContext) throws IOException
    {
        URI requestURI = requestContext.getUri();
        
        // Check if this request should be processed by the GRDDL filter
        if (!isApplicable(requestURI))
            return;
            
        // Get the JSON API endpoint URL
        URI jsonURI = getJSONURI(requestURI);
        if (jsonURI == null)
            return;
            
        // Store original URI in request context for thread-safe response processing
        requestContext.setProperty(ORIGINAL_URI_PROPERTY, requestURI);
        
        // Redirect request to JSON API endpoint
        requestContext.setUri(jsonURI);
        
        if (log.isDebugEnabled()) log.debug("Redirecting request from {} to {}", requestURI, jsonURI);
    }
    
    @Override
    public void filter(ClientRequestContext requestContext, ClientResponseContext responseContext) throws IOException
    {
        // Get the original URI from request context
        URI originalRequestURI = (URI) requestContext.getProperty(ORIGINAL_URI_PROPERTY);
        
        // Only process responses if we redirected the original request
        if (originalRequestURI == null)
            return;
            
        // Check if response is JSON
        MediaType contentType = responseContext.getMediaType();
        if (contentType == null || !MediaType.APPLICATION_JSON_TYPE.isCompatible(contentType))
            return;
            
        try (InputStream entityStream = responseContext.getEntityStream())
        {
            // Read the JSON response
            String jsonContent = new String(entityStream.readAllBytes(), StandardCharsets.UTF_8);

            // Transform JSON to RDF/XML using XSLT 3.0
            String rdfXml = transformJSONToRDF(jsonContent, originalRequestURI);

            // Replace response entity with RDF/XML
            responseContext.setEntityStream(new ByteArrayInputStream(rdfXml.getBytes(StandardCharsets.UTF_8)));
            responseContext.getHeaders().putSingle(HttpHeaders.CONTENT_TYPE, com.atomgraph.core.MediaType.APPLICATION_RDF_XML);
            responseContext.getHeaders().putSingle(HttpHeaders.CONTENT_LENGTH, String.valueOf(rdfXml.length()));

            if (log.isDebugEnabled()) log.debug("Transformed JSON response to RDF for original URI: {}", originalRequestURI);
        }
        catch (Exception ex)
        {
            if (log.isErrorEnabled()) log.error("GRDDL transformation failed for URI: {}", originalRequestURI, ex);
            throw new BadGatewayException("Failed to transform JSON to RDF", ex);
        }
    }
    
    /**
     * Transforms JSON content to RDF/XML using XSLT 3.0 initial template.
     * 
     * @param jsonContent JSON content as string
     * @param requestURI original request URI for context
     * @return RDF/XML as string
     * @throws SaxonApiException if Saxon processing fails
     * @throws java.io.IOException if I/O error occurs
     */
    protected String transformJSONToRDF(String jsonContent, URI requestURI) throws SaxonApiException, IOException
    {
        Xslt30Transformer transformer = getXsltExecutable().load30();
        
        // Set parameters - pass JSON as string parameter
        Map<QName, XdmValue> parameters = new HashMap<>();
        parameters.put(new QName("json"), new XdmAtomicValue(jsonContent));
        parameters.put(new QName("request-uri"), new XdmAtomicValue(requestURI.toString()));
        transformer.setStylesheetParameters(parameters);
        
        // Transform using initial template
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Serializer serializer = transformer.newSerializer();
        serializer.setOutputStream(outputStream);
        serializer.setOutputProperty(Serializer.Property.METHOD, "xml");
        serializer.setOutputProperty(Serializer.Property.ENCODING, StandardCharsets.UTF_8.name());
        
        transformer.callTemplate(null, serializer);
        
        return outputStream.toString(StandardCharsets.UTF_8);
    }
    
    /**
     * Determines if this filter is applicable to the given URI.
     * 
     * @param requestURI the request URI
     * @return true if this filter should process the URI
     */
    protected abstract boolean isApplicable(URI requestURI);
    
    /**
     * Returns the JSON API endpoint URI for the given request URI.
     * For example, converts YouTube video URL to oEmbed endpoint URL.
     * 
     * @param requestURI the original request URI
     * @return JSON API endpoint URI or null if not applicable
     */
    protected abstract URI getJSONURI(URI requestURI);
    
    /**
     * Returns the XSLT executable for transforming JSON to RDF.
     * 
     * @return XSLT executable
     */
    public XsltExecutable getXsltExecutable()
    {
        return xsltExecutable;
    }
    
}