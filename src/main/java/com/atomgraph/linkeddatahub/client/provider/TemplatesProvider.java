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
package com.atomgraph.linkeddatahub.client.provider;

import com.atomgraph.linkeddatahub.MediaType;
import com.atomgraph.linkeddatahub.apps.model.Application;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status.Family;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Provider;
import javax.ws.rs.ext.Providers;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.stream.StreamSource;
import org.apache.commons.io.IOUtils;
import org.glassfish.hk2.api.Factory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider which provides an XSLT stylesheet.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.client.provider.DatasetXSLTWriter
 */
@Provider
public class TemplatesProvider implements Factory<Templates> // extends PerRequestTypeInjectableProvider<Context, Templates> implements ContextResolver<Templates>
{
    
    private static final Logger log = LoggerFactory.getLogger(TemplatesProvider.class);

    private final Templates templates;
    private final SAXTransformerFactory transformerFactory;
    private final Boolean cacheStylesheet;
    
    @Context Providers providers;
    @Context UriInfo uriInfo;
    @Context HttpHeaders httpHeaders;
    
    @Inject @Named("CertClient") Client client;
    @Inject Application application;
    
    private final Map<String, Templates> appTemplatesCache = new HashMap<>();

    public TemplatesProvider(final SAXTransformerFactory transformerFactory, final URIResolver uriResolver,
            final Templates templates, final boolean cacheStylesheet)
    {
        this.templates = templates;
        this.transformerFactory = transformerFactory;
        this.cacheStylesheet = cacheStylesheet;
        this.transformerFactory.setURIResolver(uriResolver);
    }

    @Override
    public Templates provide()
    {
        return getTemplates();
    }

    @Override
    public void dispose(Templates t)
    {
    }
    
//    @Override
//    public Injectable<Templates> getInjectable(ComponentContext cc, Context a)
//    {
//        return new Injectable<Templates>()
//        {
//            @Override
//            public Templates getValue()
//            {
//                return getTemplates();
//            }
//        };
//    }
//
//    @Override
//    public Templates getContext(Class<?> type)
//    {
//        return getTemplates();
//    }
    
    public Templates getTemplates()
    {
        try
        {
            if (getApplication() != null && getApplication().getStylesheet() != null)
                return getTemplates(getApplication().getStylesheet().getURI(), getAppTemplatesCache());
            
            return templates;
        }
        catch (TransformerConfigurationException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT transformer not configured property", ex);
            // XSLTException will not be mapped because of Jersey 1.x bug: https://java.net/jira/browse/JERSEY-920
            //throw new XSLTException(ex);
            throw new WebApplicationException(ex);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT stylesheet not found or error reading it", ex);
            //throw new XSLTException(ex);
            throw new WebApplicationException(ex);
        }
    }
    
    /**
     * Get compiled XSLT stylesheet. First look in the cache, if it's enabled; otherwise read from file.
     * 
     * @param stylesheetURI
     * @param templatesCache
     * @return Templates
     * @throws java.io.IOException
     * @throws javax.xml.transform.TransformerConfigurationException
     */
    public Templates getTemplates(String stylesheetURI, Map<String, Templates> templatesCache) throws IOException, TransformerConfigurationException
    {
        if (isCacheStylesheet())
        {
            // create cache entry if it does not exist
            if (!templatesCache.containsKey(stylesheetURI))
                templatesCache.put(stylesheetURI, getTemplates(getSource(stylesheetURI)));
            
            return templatesCache.get(stylesheetURI);
        }
        
        return getTemplates(getSource(stylesheetURI));
    }

    public Templates getTemplates(Source source) throws TransformerConfigurationException
    {
        return getTransformerFactory().newTemplates(source);
    }
    
    public SAXTransformerFactory getTransformerFactory()
    {
        return transformerFactory;
    }
    
    public boolean isCacheStylesheet()
    {
        return cacheStylesheet;
    }
    
    public Map<String, Templates> getAppTemplatesCache()
    {
        return appTemplatesCache;
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
    /**
     * Supports JNDI and HTTP(S) schemes.
     * 
     * @param url
     * @return
     * @throws IOException 
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

            /*
            List<String> authHeaders = getHttpHeaders().getRequestHeader(HttpHeaders.AUTHORIZATION);
            if (authHeaders != null && !authHeaders.isEmpty())
                builder = webResource.header(HttpHeaders.AUTHORIZATION, authHeaders.get(0));
            */

            try (Response cr = builder.accept(MediaType.TEXT_XSL_TYPE).get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Family.SUCCESSFUL))
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

    public Application getApplication()
    {
//        return getProviders().getContextResolver(Application.class, null).getContext(Application.class);
        return application;
    }

    public Client getClient()
    {
//        return getProviders().getContextResolver(Client.class, null).getContext(Client.class);
        return client;
    }
    
}
