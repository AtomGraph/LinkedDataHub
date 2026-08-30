/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.client.util.StylesheetResolver;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.client.Client;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamSource;
import org.apache.commons.io.IOUtils;
import org.apache.jena.rdf.model.Resource;

/**
 * Resolves {@code xsl:import}/{@code xsl:include} URLs on the origins of this instance's applications
 * to local webapp resources, avoiding HTTP round-trips back into the same server during XSLT compilation.
 * URLs under <samp>/static/</samp> of a known application origin are read via {@link ServletContext},
 * keeping the URL as the source's system ID so that nested relative imports stay on the origin and
 * identical modules deduplicate regardless of which stylesheet imported them.
 * All other locations are delegated to {@link StylesheetResolver}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LocalStylesheetResolver extends StylesheetResolver
{

    private static final String STATIC_PATH = "/static/";

    private final com.atomgraph.linkeddatahub.Application system;
    private final ServletContext servletContext;

    /**
     * Constructs the resolver.
     *
     * @param system system application
     * @param servletContext servlet context of the webapp
     * @param client SSL-configured JAX-RS client for HTTP(S) stylesheet retrieval
     */
    public LocalStylesheetResolver(com.atomgraph.linkeddatahub.Application system, ServletContext servletContext, Client client)
    {
        super(client);
        this.system = system;
        this.servletContext = servletContext;
    }

    @Override
    public Source resolve(String href, String base) throws TransformerException
    {
        URI baseURI = URI.create(base);
        URI uri = href.isEmpty() ? baseURI : baseURI.resolve(href);

        if (("http".equals(uri.getScheme()) || "https".equals(uri.getScheme())) &&
                uri.getPath() != null && uri.getPath().startsWith(STATIC_PATH) &&
                getApp(uri) != null)
        {
            try (InputStream is = getServletContext().getResourceAsStream(uri.getPath()))
            {
                if (is != null)
                {
                    // buffer the bytes so the stream can be closed
                    byte[] bytes = IOUtils.toByteArray(is);
                    return new StreamSource(new ByteArrayInputStream(bytes), uri.toString());
                }
            }
            catch (IOException ex)
            {
                throw new TransformerException(ex);
            }
        }

        return super.resolve(href, base);
    }

    /**
     * Matches an application of this instance by the URI's origin.
     *
     * @param uri stylesheet URI
     * @return application resource or null, if none matched
     */
    public Resource getApp(URI uri)
    {
        return getSystem().getAppByOrigin(getSystem().getContextModel(), LAPP.Application, uri);
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
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

}
