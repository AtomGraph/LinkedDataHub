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

import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import org.apache.http.HttpException;
import org.apache.http.HttpHost;
import org.apache.http.HttpRequest;
import org.apache.http.conn.routing.HttpRoute;
import org.apache.http.conn.routing.HttpRoutePlanner;
import org.apache.http.protocol.HttpContext;

/**
 * Connects every request to the proxy while keeping its logical host.
 * <p>
 * The route's target carries the proxy's address, port and scheme, and the request's own host name. The request URI and
 * its <code>Host</code> header stay logical, so the platform, which routes dataspaces by <code>Host</code>, still tells
 * them apart, and the URIs it answers with are the logical ones. The TLS handshake names the logical host too (SNI): a
 * proxy that verifies client certificates refuses a request whose <code>Host</code> differs from its SNI with
 * <code>421 Misdirected Request</code>. The connection pool is keyed by route, so a connection made for one dataspace
 * is never reused for another.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ProxyRoutePlanner implements HttpRoutePlanner
{

    private final URI proxy;

    /**
     * Constructs the planner.
     *
     * @param proxy proxy URI whose scheme, host and port receive the connections (any path is ignored)
     */
    public ProxyRoutePlanner(URI proxy)
    {
        if (proxy == null || proxy.getScheme() == null || proxy.getHost() == null) throw new IllegalArgumentException("Proxy URI '" + proxy + "' is not absolute");
        this.proxy = proxy;
    }

    @Override
    public HttpRoute determineRoute(HttpHost target, HttpRequest request, HttpContext context) throws HttpException
    {
        try
        {
            // an explicit port: HttpRoute rebuilds a host with a negative one from its address, dropping the logical name
            int port = getProxy().getPort() != -1 ? getProxy().getPort() : "https".equalsIgnoreCase(getProxy().getScheme()) ? 443 : 80;
            HttpHost host = new HttpHost(InetAddress.getByName(getProxy().getHost()), target.getHostName(), port, getProxy().getScheme());

            return new HttpRoute(host, null, "https".equalsIgnoreCase(host.getSchemeName()));
        }
        catch (UnknownHostException ex)
        {
            throw new HttpException("Proxy host '" + getProxy().getHost() + "' cannot be resolved", ex);
        }
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
