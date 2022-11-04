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
package com.atomgraph.linkeddatahub.client.filter;

import java.io.IOException;
import java.net.URI;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.core.UriBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client request filter that rewrites the target URL using a proxy URL.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ClientUriRewriteFilter implements ClientRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ClientUriRewriteFilter.class);

    private final URI baseURI;
    private final String scheme, hostname;
    private final Integer port;

    /**
     * Constructs filter from URI components.
     * 
     * @param baseURI base URI
     * @param scheme new scheme
     * @param hostname new hostname
     * @param port new port number
     */
    public ClientUriRewriteFilter(URI baseURI, String scheme, String hostname, Integer port)
    {
        this.baseURI = baseURI;
        this.scheme = scheme;
        this.hostname = hostname;
        this.port = port;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        if (getBaseURI().relativize(cr.getUri()).isAbsolute()) return; // don't rewrite URIs that are not relative to the base URI (e.g. SPARQL Protocol URLs)

        String newScheme = cr.getUri().getScheme();
        if (getScheme() != null) newScheme  = getScheme();

        // cannot use the URI class because query string with special chars such as '+' gets decoded
        URI newUri = UriBuilder.fromUri(cr.getUri()).scheme(newScheme).host(getHostname()).build();

        if (log.isDebugEnabled()) log.debug("Rewriting client request URI from '{}' to '{}'", cr.getUri(), newUri);
        cr.setUri(newUri);
    }
    
    /**
     * Base URI of the application
     * 
     * @return base URI
     */
    public URI getBaseURI()
    {
        return baseURI;
    }
    
    /**
     * Scheme component of the new (rewritten) URI.
     * 
     * @return scheme string or null
     */
    public String getScheme()
    {
        return scheme;
    }
    
    /**
     * Hostname component of the new (rewritten) URI.
     * 
     * @return hostname string
     */
    public String getHostname()
    {
        return hostname;
    }

    /**
     * Port component of the new (rewritten) URI.
     * 
     * @return port number
     */
    public Integer getPort()
    {
        return port;
    }

}
