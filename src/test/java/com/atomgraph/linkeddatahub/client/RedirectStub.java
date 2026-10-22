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

import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Two HTTP servers on loopback standing in for a public origin and an internal service, with a {@link URLValidator}
 * that allows the public one only - loopback is allowed by the real validator, so the test draws the line itself.
 * <p>
 * The public server answers:
 * <ul>
 *   <li>{@code /redirect?status=&lt;code&gt;&amp;to=&lt;URI&gt;}: that status with that {@code Location};</li>
 *   <li>{@code /loop/&lt;n&gt;}: {@code 302} to {@code /loop/&lt;n+1&gt;} (relative);</li>
 *   <li>anything else: {@code 200} with a Turtle document describing {@code &lt;#me&gt;}.</li>
 * </ul>
 * The internal server answers every request with {@code 200}, and records it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RedirectStub implements AutoCloseable
{

    /** Turtle document the public server serves */
    public static final String DOCUMENT = "<#me> a <http://xmlns.com/foaf/0.1/Agent> ; <http://xmlns.com/foaf/0.1/name> \"Public\" .";

    private final HttpServer publicServer, internalServer;
    /** Requests the public server received, as {@code METHOD path} */
    public final List<String> publicRequests = new CopyOnWriteArrayList<>();
    /** Requests the internal server received, as {@code METHOD path} */
    public final List<String> internalRequests = new CopyOnWriteArrayList<>();

    /**
     * Starts both servers.
     *
     * @throws IOException if a server cannot bind
     */
    public RedirectStub() throws IOException
    {
        publicServer = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        publicServer.createContext("/", this::handlePublic);
        publicServer.start();

        internalServer = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        internalServer.createContext("/", exchange ->
        {
            internalRequests.add(exchange.getRequestMethod() + " " + exchange.getRequestURI());
            respond(exchange, 200, "<http://internal/secret> <http://internal/p> \"secret\" .");
        });
        internalServer.start();
    }

    private void handlePublic(HttpExchange exchange) throws IOException
    {
        URI uri = exchange.getRequestURI();
        publicRequests.add(exchange.getRequestMethod() + " " + uri);
        exchange.getRequestBody().readAllBytes();
        String path = uri.getPath();

        if (path.equals("/redirect"))
        {
            String status = null, to = null;
            for (String pair : uri.getRawQuery().split("&"))
            {
                String[] kv = pair.split("=", 2);
                if (kv[0].equals("status")) status = kv[1];
                if (kv[0].equals("to")) to = URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
            }
            exchange.getResponseHeaders().add("Location", to);
            exchange.sendResponseHeaders(Integer.parseInt(status), -1);
            exchange.close();
            return;
        }

        if (path.startsWith("/loop/"))
        {
            int n = Integer.parseInt(path.substring("/loop/".length()));
            exchange.getResponseHeaders().add("Location", String.valueOf(n + 1));
            exchange.sendResponseHeaders(302, -1);
            exchange.close();
            return;
        }

        respond(exchange, 200, DOCUMENT);
    }

    private static void respond(HttpExchange exchange, int status, String turtle) throws IOException
    {
        byte[] body = turtle.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "text/turtle");
        if ("HEAD".equals(exchange.getRequestMethod()))
        {
            exchange.sendResponseHeaders(status, -1);
            exchange.close();
            return;
        }
        exchange.sendResponseHeaders(status, body.length);
        try (OutputStream out = exchange.getResponseBody())
        {
            out.write(body);
        }
    }

    /**
     * Returns a URI on the public server.
     *
     * @param pathAndQuery path and query
     * @return URI
     */
    public URI publicURI(String pathAndQuery)
    {
        return URI.create("http://127.0.0.1:" + publicServer.getAddress().getPort() + pathAndQuery);
    }

    /**
     * Returns a URI on the internal server.
     *
     * @param pathAndQuery path and query
     * @return URI
     */
    public URI internalURI(String pathAndQuery)
    {
        return URI.create("http://127.0.0.1:" + internalServer.getAddress().getPort() + pathAndQuery);
    }

    /**
     * Returns a public URI that redirects to the given URI.
     *
     * @param status redirect status
     * @param to {@code Location} value
     * @return URI
     */
    public URI redirect(int status, String to)
    {
        return publicURI("/redirect?status=" + status + "&to=" + URLEncoder.encode(to, StandardCharsets.UTF_8));
    }

    /**
     * Returns a validator that refuses every URI but the public server's, as if they resolved to an internal address.
     *
     * @return URL validator
     */
    public URLValidator validator()
    {
        int allowed = publicServer.getAddress().getPort();
        return new URLValidator(false)
        {
            @Override
            public URI validate(URI uri)
            {
                if (uri.getPort() != allowed) throw new InternalURLException(uri, uri.getHost());
                return super.validate(uri);
            }
        };
    }

    @Override
    public void close()
    {
        publicServer.stop(0);
        internalServer.stop(0);
    }

}
