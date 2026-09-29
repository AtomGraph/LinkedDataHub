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
import org.glassfish.jersey.client.ClientProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client request filter that rewrites target URLs matching the configured host to internal proxy URLs.
 * This improves performance by routing internal requests through the Docker network instead of external network.
 * <p>
 * A request to this instance's own URL differs from every other outbound request in one way: it is answered by
 * one of this instance's own request threads, and the thread that sent it may be one of them. A server-side
 * render that asks its own dataspace for labels holds a thread while it waits; when every thread is such a
 * render, none is free to answer any of them, and nothing completes until a read times out. So a self-call
 * waits a few seconds and then fails, and the caller renders without it (the stylesheets catch the failure),
 * rather than waiting for the client's read timeout, which is sized for a stalled backend.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ClientUriRewriteFilter implements ClientRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ClientUriRewriteFilter.class);

    private final String host;
    private final String proxyScheme, proxyHost;
    private final Integer proxyPort, selfRequestTimeout;

    /**
     * Constructs filter from URI components.
     *
     * @param host external hostname to match, including subdomains (e.g., "localhost", "linkeddatahub.com")
     * @param proxyScheme proxy scheme to rewrite to (e.g., "http")
     * @param proxyHost proxy hostname to rewrite to (e.g., "nginx")
     * @param proxyPort proxy port to rewrite to (e.g., 9443)
     * @param selfRequestTimeout connect and read timeout in milliseconds for requests to the matched host, or null to leave the client's
     */
    public ClientUriRewriteFilter(String host, String proxyScheme, String proxyHost, Integer proxyPort, Integer selfRequestTimeout)
    {
        this.host = host;
        this.proxyScheme = proxyScheme;
        this.proxyHost = proxyHost;
        this.proxyPort = proxyPort;
        this.selfRequestTimeout = selfRequestTimeout;
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

        // Preserve subdomain prefix only when proxyHost is the same domain as host, to prevent
        // the HTTP client reusing a connection with a different TLS SNI (which causes 421).
        // When proxyHost is a distinct internal hostname (e.g. "nginx"), no collision is possible.
        String newHost = getProxyHost();
        if (cr.getUri().getHost().endsWith("." + getHost()) && getProxyHost().equals(getHost()))
        {
            String subdomainPrefix = cr.getUri().getHost().substring(0, cr.getUri().getHost().length() - getHost().length()); // e.g. "admin."
            newHost = subdomainPrefix + getProxyHost();
        }

        // the answer has to come from one of this instance's own request threads: bound the wait, unless the
        // caller set its own. The Apache connector reads both properties per request.
        if (getSelfRequestTimeout() != null)
        {
            if (cr.getProperty(ClientProperties.READ_TIMEOUT) == null) cr.setProperty(ClientProperties.READ_TIMEOUT, getSelfRequestTimeout());
            if (cr.getProperty(ClientProperties.CONNECT_TIMEOUT) == null) cr.setProperty(ClientProperties.CONNECT_TIMEOUT, getSelfRequestTimeout());
        }

        // cannot use the URI class because query string with special chars such as '+' gets decoded
        URI newUri = UriBuilder.fromUri(cr.getUri()).scheme(newScheme).host(newHost).port(getProxyPort()).build();

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

    /**
     * Connect and read timeout for requests to the matched host.
     *
     * @return timeout in milliseconds, or null if the client's own applies
     */
    public Integer getSelfRequestTimeout()
    {
        return selfRequestTimeout;
    }

}
