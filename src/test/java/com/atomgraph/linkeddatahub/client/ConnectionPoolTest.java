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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.linkeddatahub.Application;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpsConfigurator;
import com.sun.net.httpserver.HttpsExchange;
import com.sun.net.httpserver.HttpsParameters;
import com.sun.net.httpserver.HttpsServer;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.core.Response;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.TrustManagerFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.fail;

/**
 * Tests that the clients' connection pools survive the connectors Jersey releases, and that their TLS
 * connections are reused.
 * <p>
 * A target with a filter registered on it - such as the WebID delegation filter - runs on a connector of its own
 * over the client's pool. Once such a connector is garbage-collected Jersey closes it, and unless the pool is shared
 * that shuts the pool down: every later request fails with "Connection pool shut down" (jersey#4449). Separately, a
 * connection that presented a client certificate is released tagged with its TLS principal and never leased again
 * unless the pool releases it untagged (jersey#2855).
 * <p>
 * Runs against local servers - plain HTTP, and HTTPS asking for a client certificate - with the collector run
 * between requests, as a long-running server's would.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ConnectionPoolTest
{

    private static final int REQUESTS = 20;
    private static final String PASSWORD = "changeit";

    private static HttpServer http;
    private static HttpsServer https;
    /** Remote ports the servers saw: one per connection */
    private static final Set<Integer> connections = ConcurrentHashMap.newKeySet();
    private static volatile String peer;

    @BeforeAll
    public static void start() throws Exception
    {
        https = HttpsServer.create(new InetSocketAddress("localhost", 0), 0);
        https.setHttpsConfigurator(new HttpsConfigurator(serverContext())
        {
            @Override
            public void configure(HttpsParameters params)
            {
                SSLParameters ssl = getSSLContext().getDefaultSSLParameters();
                ssl.setWantClientAuth(true); // asked for, not required: the no-cert client connects too
                params.setSSLParameters(ssl);
            }
        });
        http = HttpServer.create(new InetSocketAddress("localhost", 0), 0);

        for (HttpServer server : new HttpServer[] { https, http })
        {
            server.createContext("/", exchange ->
            {
                connections.add(exchange.getRemoteAddress().getPort());
                if (exchange instanceof HttpsExchange secure)
                {
                    try
                    {
                        peer = secure.getSSLSession().getPeerPrincipal().getName();
                    }
                    catch (SSLPeerUnverifiedException ex)
                    {
                        peer = null;
                    }
                }
                byte[] body = "ok".getBytes(StandardCharsets.UTF_8);
                exchange.sendResponseHeaders(200, body.length);
                try (OutputStream out = exchange.getResponseBody())
                {
                    out.write(body);
                }
            });
            server.start();
        }
    }

    @AfterAll
    public static void stop()
    {
        if (https != null) https.stop(0);
        if (http != null) http.stop(0);
    }

    @Test
    public void clientPoolSurvivesReleasedConnectorsAndReusesItsCertConnection() throws Exception
    {
        Client client = Application.getClient(load("agent.p12"), PASSWORD, load("agent-trust.p12"), 20, 100, null, false, null, null, null, null, null);

        requests(client, httpsUrl());

        assertEquals("CN=agent", peer, "the client certificate is presented");
        assertEquals(1, connections.size(), "the connection that presented the certificate is reused");
    }

    @Test
    public void noCertClientPoolSurvivesReleasedConnectorsAndReusesItsConnection() throws Exception
    {
        Client client = Application.getNoCertClient(load("agent-trust.p12"), 20, 100, null, null, null, null, null, null);

        requests(client, httpsUrl());

        assertNull(peer, "no client certificate is presented");
        assertEquals(1, connections.size(), "the connection is reused");
    }

    @Test
    public void verifiedClientPoolSurvivesReleasedConnectors() throws Exception
    {
        // trusts the JVM's CAs only, so over plain HTTP: the pool is what is under test
        Client client = Application.getVerifiedClient(20, 100, null, null, null, null, null, null);

        requests(client, "http://localhost:" + http.getAddress().getPort() + "/");

        assertEquals(1, connections.size(), "the connection is reused");
    }

    /** Requests through a target with a filter of its own each, collecting between them. */
    private static void requests(Client client, String url) throws InterruptedException
    {
        connections.clear();
        peer = null;

        for (int i = 1; i <= REQUESTS; i++)
        {
            try (Response response = client.target(url).
                    register((ClientRequestFilter) request -> request.getHeaders().add("X-Request", "1")).
                    request().get())
            {
                assertEquals(200, response.getStatus());
                assertEquals("ok", response.readEntity(String.class));
            }
            catch (RuntimeException ex)
            {
                fail("Request " + i + " of " + REQUESTS + " failed: " + ex.getMessage(), ex);
            }

            for (int gc = 0; gc < 3; gc++)
            {
                System.gc();
                Thread.sleep(20);
            }
        }
    }

    private static String httpsUrl()
    {
        return "https://localhost:" + https.getAddress().getPort() + "/";
    }

    private static SSLContext serverContext() throws Exception
    {
        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(load("server.p12"), PASSWORD.toCharArray());
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(load("server-trust.p12"));

        SSLContext ctx = SSLContext.getInstance("TLS");
        ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
        return ctx;
    }

    private static KeyStore load(String name) throws Exception
    {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        try (InputStream in = ConnectionPoolTest.class.getResourceAsStream("ssl/" + name))
        {
            keyStore.load(in, PASSWORD.toCharArray());
        }
        return keyStore;
    }

}
