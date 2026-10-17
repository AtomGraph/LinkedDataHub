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

import java.net.URI;
import org.apache.http.HttpHost;
import org.apache.http.conn.routing.HttpRoute;
import org.apache.http.message.BasicHttpRequest;
import org.apache.http.protocol.BasicHttpContext;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * The route to a proxy URI without an explicit port, e.g. <code>https://example.org/</code> (what
 * <code>install.sh</code> scripts pass when the base itself is the proxy). <code>HttpRoute</code> normalizes a host
 * with a negative port by rebuilding it from its address, which names the proxy, not the logical host - so the TLS
 * handshake named the proxy and nginx answered <code>421</code>.
 */
public class ProxyRoutePlannerTest
{

    @Test
    public void portlessProxyKeepsLogicalHost() throws Exception
    {
        HttpRoute route = new ProxyRoutePlanner(URI.create("https://127.0.0.1/")).
            determineRoute(new HttpHost("admin.docs.example.org", 443, "https"), new BasicHttpRequest("HEAD", "/"), new BasicHttpContext());

        assertEquals("admin.docs.example.org", route.getTargetHost().getHostName());
        assertEquals(443, route.getTargetHost().getPort());
    }

    @Test
    public void portlessHttpProxyDefaultsTo80() throws Exception
    {
        HttpRoute route = new ProxyRoutePlanner(URI.create("http://127.0.0.1/")).
            determineRoute(new HttpHost("admin.docs.example.org", 80, "http"), new BasicHttpRequest("HEAD", "/"), new BasicHttpContext());

        assertEquals("admin.docs.example.org", route.getTargetHost().getHostName());
        assertEquals(80, route.getTargetHost().getPort());
    }

}
