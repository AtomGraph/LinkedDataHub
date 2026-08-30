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
import jakarta.json.JsonArrayBuilder;
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
    private int commitCount = 2; // number of commits in the fake file history

    private static Optional<String> queryParam(String query, String name)
    {
        if (query == null) return Optional.empty();

        for (String pair : query.split("&"))
            if (pair.startsWith(name + "=")) return Optional.of(pair.substring(name.length() + 1));

        return Optional.empty();
    }

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

        if (path.equals("/repos/acme/graphs/commits"))
        {
            // serve the requested page of a synthetic history of commitCount commits, most recent first
            int page = Integer.parseInt(queryParam(exchange.getRequestURI().getQuery(), "page").orElse("1"));
            int offset = (page - 1) * GitHubClient.COMMITS_PER_PAGE;

            JsonArrayBuilder array = Json.createArrayBuilder();
            for (int i = offset; i < Math.min(offset + GitHubClient.COMMITS_PER_PAGE, commitCount); i++)
            {
                int sequence = commitCount - i; // sha-N counts down from the newest commit
                array.add(Json.createObjectBuilder().
                    add("sha", "sha-" + sequence).
                    add("commit", Json.createObjectBuilder().
                        add("author", Json.createObjectBuilder().
                            add("date", Instant.parse("2026-08-17T10:00:00Z").plusSeconds(3600L * (sequence - 1)).toString()).
                            add("name", "https://localhost/agent#this"))));
            }

            respond(exchange, 200, array.build().toString());
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

    @Test
    public void testListCommits()
    {
        var commits = gitHubClient.listCommits("graphs/doc.nt");

        assertEquals(2, commits.size());
        assertEquals(new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T11:00:00Z"), "https://localhost/agent#this"), commits.get(0));
        assertTrue(received.get(0).uri().contains("path=graphs") && received.get(0).uri().contains("sha=main"));
    }

    @Test
    public void testListCommitsPagesThroughHistory()
    {
        commitCount = GitHubClient.COMMITS_PER_PAGE + 50;

        var commits = gitHubClient.listCommits("graphs/doc.nt");

        // a TimeMap has to be comprehensive, so a full first page must not end the walk
        assertEquals(GitHubClient.COMMITS_PER_PAGE + 50, commits.size());
        assertEquals(2, received.size());
        assertTrue(received.get(1).uri().contains("page=2"));
        assertEquals("sha-" + (GitHubClient.COMMITS_PER_PAGE + 50), commits.get(0).sha()); // newest first
        assertEquals("sha-1", commits.get(commits.size() - 1).sha());
    }

    @Test
    public void testListCommitsStopsOnExactPageBoundary()
    {
        commitCount = GitHubClient.COMMITS_PER_PAGE;

        var commits = gitHubClient.listCommits("graphs/doc.nt");

        // a full page is followed by an empty one, which ends the walk
        assertEquals(GitHubClient.COMMITS_PER_PAGE, commits.size());
        assertEquals(2, received.size());
    }

}
