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

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * In-process HTTP server that answers every request with a canned status and body, and records
 * the last request it saw. Lets the tests drive the real client stack - Jersey, the Apache
 * connector, the PKCS12 client certificate - without a LinkedDataHub instance.
 */
public class StubServer implements AutoCloseable
{

    private final HttpServer server;

    private volatile int status = 200;
    private volatile String body = "";
    private volatile String contentType = "text/turtle";
    private final Map<String, String> responseHeaders = new LinkedHashMap<>();
    private final Map<String, Route> routes = new LinkedHashMap<>();

    private volatile String lastMethod;
    private volatile String lastTarget;
    private volatile String lastBody;
    private volatile Map<String, String> lastHeaders = Map.of();

    /**
     * Starts the server on an ephemeral loopback port.
     *
     * @throws IOException if the socket cannot be bound
     */
    public StubServer() throws IOException
    {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);

        server.createContext("/", exchange ->
        {
            lastMethod = exchange.getRequestMethod();
            lastTarget = exchange.getRequestURI().toString();
            lastBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);

            Map<String, String> headers = new LinkedHashMap<>();
            exchange.getRequestHeaders().forEach((name, values) -> headers.put(name.toLowerCase(Locale.ROOT), values.get(0)));
            lastHeaders = headers;

            Route route = routes.get(exchange.getRequestURI().getPath());
            byte[] out = (route != null ? route.body() : body).getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", route != null ? route.contentType() : contentType);
            responseHeaders.forEach((name, value) -> exchange.getResponseHeaders().add(name, value));
            exchange.sendResponseHeaders(route != null ? route.status() : status, out.length == 0 ? -1 : out.length);
            if (out.length > 0) exchange.getResponseBody().write(out);
            exchange.close();
        });

        server.start();
    }

    /**
     * Returns the base URI the server is listening on.
     *
     * @return base URI with a trailing slash
     */
    public URI baseURI()
    {
        return URI.create("http://127.0.0.1:" + server.getAddress().getPort() + "/");
    }

    /** A canned response bound to one request path, for the commands that read more than one document. */
    private record Route(int status, String contentType, String body) { }

    /**
     * Binds a canned response to a request path, taking precedence over the default one.
     *
     * @param path request path
     * @param status HTTP status code
     * @param contentType response media type
     * @param body response body
     * @return this server
     */
    public StubServer respondsTo(String path, int status, String contentType, String body)
    {
        routes.put(path, new Route(status, contentType, body));
        return this;
    }

    /**
     * Sets the canned response.
     *
     * @param status HTTP status code
     * @param body response body
     * @return this server
     */
    public StubServer responds(int status, String body)
    {
        this.status = status;
        this.body = body;
        return this;
    }

    /**
     * Sets the canned response content type.
     *
     * @param contentType response media type
     * @return this server
     */
    public StubServer respondsWithType(String contentType)
    {
        this.contentType = contentType;
        return this;
    }

    /**
     * Adds a header to the canned response.
     *
     * @param name header name
     * @param value header value
     * @return this server
     */
    public StubServer respondsWithHeader(String name, String value)
    {
        responseHeaders.put(name, value);
        return this;
    }

    /**
     * Returns the method of the last request.
     *
     * @return HTTP method, or null if no request was made
     */
    public String getLastMethod()
    {
        return lastMethod;
    }

    /**
     * Returns the request target (path and query) of the last request.
     *
     * @return request target, or null if no request was made
     */
    public String getLastTarget()
    {
        return lastTarget;
    }

    /**
     * Returns a request header of the last request.
     *
     * @param name header name, matched case-insensitively
     * @return header value, or null if the header was not sent
     */
    public String getLastHeader(String name)
    {
        return lastHeaders.get(name.toLowerCase(Locale.ROOT));
    }

    /**
     * Returns the body of the last request.
     *
     * @return request body, or null if no request was made
     */
    public String getLastBody()
    {
        return lastBody;
    }

    @Override
    public void close()
    {
        server.stop(0);
    }

}
