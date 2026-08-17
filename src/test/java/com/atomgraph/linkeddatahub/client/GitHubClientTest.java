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

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the GitHub API client against a local fake server.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GitHubClientTest
{

    private HttpServer server;
    private Client httpClient;
    private GitHubClient gitHubClient;

    /** Requests received by the fake server: method, path+query, Accept header, body */
    private record Received(String method, String uri, String accept, String body) { }
    private final List<Received> received = new ArrayList<>();

    private String fileSha = null; // null = file does not exist on the fake server
    private byte[] fileContent = null;
    private int rateLimitResponses = 0; // number of upcoming requests to answer with 429

    @BeforeEach
    public void setUp() throws IOException
    {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/", this::handle);
        server.start();

        httpClient = ClientBuilder.newClient();
        gitHubClient = new GitHubClient(httpClient, URI.create("http://localhost:" + server.getAddress().getPort()),
            "test-token", "acme", "graphs", "main");
    }

    @AfterEach
    public void tearDown()
    {
        httpClient.close();
        server.stop(0);
    }

    private void handle(HttpExchange exchange) throws IOException
    {
        String body;
        try (InputStream in = exchange.getRequestBody())
        {
            body = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
        received.add(new Received(exchange.getRequestMethod(), exchange.getRequestURI().toString(),
            exchange.getRequestHeaders().getFirst("Accept"), body));

        if (rateLimitResponses > 0)
        {
            rateLimitResponses--;
            exchange.getResponseHeaders().set("Retry-After", "0");
            exchange.sendResponseHeaders(429, -1);
            exchange.close();
            return;
        }

        String path = exchange.getRequestURI().getPath();
        String method = exchange.getRequestMethod();

        if (path.startsWith("/repos/acme/graphs/contents/"))
        {
            switch (method)
            {
                case "GET" ->
                {
                    if (fileSha == null)
                    {
                        respond(exchange, 404, "{\"message\": \"Not Found\"}");
                        return;
                    }
                    if ("application/vnd.github.raw+json".equals(exchange.getRequestHeaders().getFirst("Accept")))
                    {
                        exchange.getResponseHeaders().set("Content-Type", "application/vnd.github.raw+json");
                        exchange.sendResponseHeaders(200, fileContent.length);
                        exchange.getResponseBody().write(fileContent);
                        exchange.close();
                        return;
                    }
                    respond(exchange, 200, Json.createObjectBuilder().add("sha", fileSha).build().toString());
                }
                case "PUT" ->
                {
                    JsonObject json = Json.createReader(new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8))).readObject();
                    boolean creating = fileSha == null;
                    fileContent = Base64.getDecoder().decode(json.getString("content"));
                    fileSha = "blob-" + received.size();
                    respond(exchange, creating ? 201 : 200, Json.createObjectBuilder().
                        add("commit", Json.createObjectBuilder().add("sha", "commit-" + received.size())).
                        add("content", Json.createObjectBuilder().add("sha", fileSha)).
                        build().toString());
                }
                case "DELETE" ->
                {
                    fileSha = null;
                    fileContent = null;
                    respond(exchange, 200, "{}");
                }
                default -> respond(exchange, 405, "{}");
            }
            return;
        }

        if (path.startsWith("/repos/acme/graphs/commits/"))
        {
            respond(exchange, 200, Json.createObjectBuilder().
                add("commit", Json.createObjectBuilder().
                    add("committer", Json.createObjectBuilder().add("date", "2026-08-17T10:00:00Z"))).
                build().toString());
            return;
        }

        respond(exchange, 404, "{}");
    }

    private void respond(HttpExchange exchange, int status, String json) throws IOException
    {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    @Test
    public void testPutFileCreatesWithoutSha()
    {
        GitHubClient.Commit commit = gitHubClient.putFile("graphs/doc.nt", "<a> <b> <c> .\n".getBytes(StandardCharsets.UTF_8), "PUT https://localhost/doc/", "https://localhost/agent#this");

        // create: SHA probe 404s, then PUT without "sha"
        assertEquals(2, received.size());
        assertEquals("GET", received.get(0).method());
        assertEquals("PUT", received.get(1).method());
        JsonObject put = Json.createReader(new ByteArrayInputStream(received.get(1).body().getBytes(StandardCharsets.UTF_8))).readObject();
        assertTrue(!put.containsKey("sha"));
        assertEquals("main", put.getString("branch"));
        assertEquals("https://localhost/agent#this", put.getJsonObject("author").getString("name"));
        assertEquals("<a> <b> <c> .\n", new String(Base64.getDecoder().decode(put.getString("content")), StandardCharsets.UTF_8));
        assertEquals("commit-2", commit.commitSha());
    }

    @Test
    public void testPutFileUpdatesWithSha()
    {
        gitHubClient.putFile("graphs/doc.nt", "v1".getBytes(StandardCharsets.UTF_8), "PUT", "agent");
        received.clear();

        gitHubClient.putFile("graphs/doc.nt", "v2".getBytes(StandardCharsets.UTF_8), "PUT", "agent");

        // update: SHA probe succeeds, then PUT with "sha"
        assertEquals(2, received.size());
        JsonObject put = Json.createReader(new ByteArrayInputStream(received.get(1).body().getBytes(StandardCharsets.UTF_8))).readObject();
        assertTrue(put.containsKey("sha"));
        assertArrayEquals("v2".getBytes(StandardCharsets.UTF_8), fileContent);
    }

    @Test
    public void testGetFileAtCommitUsesRawMediaType()
    {
        gitHubClient.putFile("graphs/doc.nt", "raw content".getBytes(StandardCharsets.UTF_8), "PUT", "agent");
        received.clear();

        Optional<byte[]> content = gitHubClient.getFileAtCommit("graphs/doc.nt", "commit-2");

        assertArrayEquals("raw content".getBytes(StandardCharsets.UTF_8), content.get());
        assertEquals("application/vnd.github.raw+json", received.get(0).accept());
    }

    @Test
    public void testGetFileAtCommitNotFound()
    {
        assertTrue(gitHubClient.getFileAtCommit("graphs/missing.nt", "commit-1").isEmpty());
    }

    @Test
    public void testDeleteFile()
    {
        gitHubClient.putFile("graphs/doc.nt", "v1".getBytes(StandardCharsets.UTF_8), "PUT", "agent");
        received.clear();

        gitHubClient.deleteFile("graphs/doc.nt", "DELETE https://localhost/doc/", "agent");

        assertEquals(2, received.size()); // SHA probe + DELETE
        assertEquals("DELETE", received.get(1).method());
        JsonObject delete = Json.createReader(new ByteArrayInputStream(received.get(1).body().getBytes(StandardCharsets.UTF_8))).readObject();
        assertTrue(delete.containsKey("sha"));
    }

    @Test
    public void testDeleteMissingFileIsNoOp()
    {
        gitHubClient.deleteFile("graphs/missing.nt", "DELETE", "agent");

        assertEquals(1, received.size()); // only the SHA probe, no DELETE
    }

    @Test
    public void testRateLimitedRequestIsRetried()
    {
        gitHubClient.putFile("graphs/doc.nt", "v1".getBytes(StandardCharsets.UTF_8), "PUT", "agent");
        received.clear();
        rateLimitResponses = 1;

        Optional<byte[]> content = gitHubClient.getFileAtCommit("graphs/doc.nt", "commit-2");

        assertTrue(content.isPresent());
        assertEquals(2, received.size()); // 429 response, then the retry
    }

    @Test
    public void testGetCommitDate()
    {
        assertEquals(Optional.of(Instant.parse("2026-08-17T10:00:00Z")), gitHubClient.getCommitDate("commit-1"));
    }

}
