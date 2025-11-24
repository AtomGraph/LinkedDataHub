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
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.UriBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client request filter that rewrites target URLs matching the configured host to internal proxy URLs.
 * This improves performance by routing internal requests through the Docker network instead of external network.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ClientUriRewriteFilter implements ClientRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ClientUriRewriteFilter.class);

    private final String host;
    private final String proxyScheme, proxyHost;
    private final Integer proxyPort;

    /**
     * Constructs filter from URI components.
     *
     * @param host external hostname to match, including subdomains (e.g., "localhost", "linkeddatahub.com")
     * @param proxyScheme proxy scheme to rewrite to (e.g., "http")
     * @param proxyHost proxy hostname to rewrite to (e.g., "nginx")
     * @param proxyPort proxy port to rewrite to (e.g., 9443)
     */
    public ClientUriRewriteFilter(String host, String proxyScheme, String proxyHost, Integer proxyPort)
    {
        this.host = host;
        this.proxyScheme = proxyScheme;
        this.proxyHost = proxyHost;
        this.proxyPort = proxyPort;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        // Only rewrite requests to our own host (or subdomains), not external URLs
        if (!cr.getUri().getHost().equals(getHost()) && !cr.getUri().getHost().endsWith("." + getHost())) return;

        // Preserve original host for nginx routing
        String originalHost = cr.getUri().getHost();
        if (cr.getUri().getPort() != -1) originalHost += ":" + cr.getUri().getPort();
        cr.getHeaders().putSingle(HttpHeaders.HOST, originalHost);

        String newScheme = cr.getUri().getScheme();
        if (getProxyScheme() != null) newScheme = getProxyScheme();

        // cannot use the URI class because query string with special chars such as '+' gets decoded
        URI newUri = UriBuilder.fromUri(cr.getUri()).scheme(newScheme).host(getProxyHost()).port(getProxyPort()).build();

        if (log.isDebugEnabled()) log.debug("Rewriting client request URI from '{}' to '{}'", cr.getUri(), newUri);
        cr.setUri(newUri);
    }

    /**
     * External hostname to match (including subdomains).
     *
     * @return hostname string (e.g., "localhost", "linkeddatahub.com")
     */
    public String getHost()
    {
        return host;
    }

    /**
     * Proxy scheme to rewrite to.
     *
     * @return scheme string or null (e.g., "http")
     */
    public String getProxyScheme()
    {
        return proxyScheme;
    }

    /**
     * Proxy hostname to rewrite to.
     *
     * @return hostname string (e.g., "nginx")
     */
    public String getProxyHost()
    {
        return proxyHost;
    }

    /**
     * Proxy port to rewrite to.
     *
     * @return port number (e.g., 9443)
     */
    public Integer getProxyPort()
    {
        return proxyPort;
    }

}
