/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.http;

import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;

/**
 * Sends every request to the proxy while keeping the logical <code>Host</code>.
 * <p>
 * The connection goes to the proxy's scheme, host and port; the path, query and the <code>Host</code> header stay those
 * of the logical URI. The platform routes dataspaces by <code>Host</code>, so an admin request through the end-user
 * proxy still reaches the admin dataspace, and the URIs the platform answers with are the logical ones.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ProxyRewriteFilter implements ClientRequestFilter
{

    private final URI proxy;

    /**
     * Constructs the filter.
     *
     * @param proxy proxy URI whose scheme, host and port receive the connection (any path is ignored)
     */
    public ProxyRewriteFilter(URI proxy)
    {
        if (proxy == null || proxy.getScheme() == null || proxy.getHost() == null) throw new IllegalArgumentException("Proxy URI '" + proxy + "' is not absolute");
        this.proxy = proxy;
    }

    @Override
    public void filter(ClientRequestContext request)
    {
        URI uri = request.getUri();
        if (uri.getRawAuthority() == null) throw new IllegalArgumentException("URI '" + uri + "' is not absolute");

        request.getHeaders().putSingle(HttpHeaders.HOST, uri.getRawAuthority());
        // UriBuilder rather than string surgery, so an encoded path or query survives untouched
        request.setUri(UriBuilder.fromUri(uri).scheme(getProxy().getScheme()).host(getProxy().getHost()).port(getProxy().getPort()).build());
    }

    /**
     * Returns the proxy URI.
     *
     * @return proxy URI
     */
    public URI getProxy()
    {
        return proxy;
    }

}
