/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.MediaType;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Map;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.Priorities;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Response filter that loads and compiles the XSLT stylesheet of the application.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 200)
public class XsltExecutableFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(XsltExecutableFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject javax.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> application;
    
    @Context UriInfo uriInfo;
    
    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        // we only need the XSLT stylesheet if the response has (X)HTML media type
        if (resp.getMediaType() != null &&
            (resp.getMediaType().isCompatible(MediaType.TEXT_HTML_TYPE) || resp.getMediaType().isCompatible(MediaType.APPLICATION_XHTML_XML_TYPE)))
        {
            URI stylesheet = getApplication().getStylesheet() != null ? URI.create(getApplication().getStylesheet().getURI()) : null;

            if (stylesheet != null) req.setProperty(AC.stylesheet.getURI(), getXsltExecutable(stylesheet));
            else req.setProperty(AC.stylesheet.getURI(), getSystem().getXsltExecutable());
        }
    }
    
    /**
     * Returns XSLT executable for the given stylesheet URI.
     * 
     * @param stylesheet stylesheet URI
     * @return XSLT executable
     */
    public XsltExecutable getXsltExecutable(URI stylesheet)
    {
        try
        {
            return getXsltExecutable(stylesheet, getXsltExecutableCache());
        }
        catch (SaxonApiException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT transformer not configured property", ex);
            throw new InternalServerErrorException(ex); // TO-DO: throw new XSLTException(ex);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT stylesheet not found or error reading it", ex);
            throw new InternalServerErrorException(ex); // TO-DO: throw new XSLTException(ex);
        }
    }
    
    /**
     * Returns compiled XSLT stylesheet. First looks in the cache, if it's enabled; otherwise read from URL.
     * 
     * @param stylesheet stylesheet URI
     * @param xsltExecCache executable cache
     * @return XsltExecutable XSLT executable
     * @throws java.io.IOException I/O error
     * @throws SaxonApiException Saxon error
     */
    public XsltExecutable getXsltExecutable(URI stylesheet, Map<URI, XsltExecutable> xsltExecCache) throws IOException, SaxonApiException
    {
        if (isCacheStylesheet())
        {
            // create cache entry if it does not exist
            if (!xsltExecCache.containsKey(stylesheet))
                xsltExecCache.put(stylesheet, getXsltExecutable(getSource(stylesheet.toString())));
            
            return xsltExecCache.get(stylesheet);
        }
        
        return getXsltExecutable(getSource(stylesheet.toString()));
    }
    
    /**
     * Compiles XSLT document source into an XSLT executable.
     * 
     * @param source XSLT document source
     * @return XSLT executable
     * @throws SaxonApiException Saxon error
     */
    public XsltExecutable getXsltExecutable(Source source) throws SaxonApiException
    {
        return getXsltCompiler().compile(source);
    }
    
    /**
     * Loads XML document source from URL.
     * Supports JNDI and HTTP(S) schemes.
     * 
     * @param url document URL
     * @return document source
     * @throws IOException I/O error
     */
    public Source getSource(String url) throws IOException
    {
        if (url == null) throw new IllegalArgumentException("URI name cannot be null");
        
        URI uri = getUriInfo().getBaseUri().resolve(url);
        if (log.isDebugEnabled()) log.debug("Loading Source using '{}' scheme from URL '{}'", uri.getScheme(), uri);
        
        if (uri.getScheme().equals("file") || uri.getScheme().equals("jndi"))
            try (InputStream is = uri.toURL().openStream())
            {
                byte[] bytes = IOUtils.toByteArray(is);
                return new StreamSource(new ByteArrayInputStream(bytes), url);
            }
        
        if (uri.getScheme().equals("http") || uri.getScheme().equals("https"))
        {
            WebTarget webResource = getClient().target(uri);
            Invocation.Builder builder = webResource.request();

            try (Response cr = builder.accept(MediaType.TEXT_XSL_TYPE).get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    throw new IOException("XSLT stylesheet could not be successfully loaded over HTTP");

                // buffer the stylesheet stream so we can close Response
                try (InputStream is = cr.readEntity(InputStream.class))
                {
                    byte[] bytes = IOUtils.toByteArray(is);
                    return new StreamSource(new ByteArrayInputStream(bytes), uri.toString());
                }
            }
        }
        
        return null;
    }

    /**
     * Returns HTTP client.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return getSystem().getClient();
    }

    /**
     * Returns XSLT compiler.
     * 
     * @return XSLT compiler
     */
    public XsltCompiler getXsltCompiler()
    {
        return getSystem().getXsltCompiler();
    }

    /**
     * Returns true if XSLT stylesheets are cached.
     * 
     * @return true if cached
     */
    public boolean isCacheStylesheet()
    {
        return getSystem().isCacheStylesheet();
    }
    
    /**
     * Returns the cache map for XSLT executables.
     * 
     * @return stylesheet URI to executable map
     */
    public Map<URI, XsltExecutable> getXsltExecutableCache()
    {
        return getSystem().getXsltExecutableCache();
    }
    
    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    /**
     * Returns current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application.get();
    }

    /**
     * Returns URI info of the current request.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
}
