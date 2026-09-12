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

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;
import jakarta.json.JsonValue;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.function.Supplier;
import org.glassfish.jersey.client.ClientProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * GitHub REST API client for graph versioning.
 * Wraps the Contents and Commits endpoints used to mirror named graphs as files in a repository.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://docs.github.com/en/rest/repos/contents">GitHub Contents API</a>
 */
public class GitHubClient
{

    private static final Logger log = LoggerFactory.getLogger(GitHubClient.class);

    /** Default GitHub API base URI */
    public static final URI API_BASE = URI.create("https://api.github.com");
    /** GitHub API JSON media type */
    public static final String GITHUB_JSON = "application/vnd.github+json";
    /** GitHub API raw content media type */
    public static final String GITHUB_RAW = "application/vnd.github.raw+json";
    /** Author email used on commits (the author name carries the agent's WebID) */
    public static final String AUTHOR_EMAIL = "noreply@linkeddatahub.invalid";
    /** Maximum retries on rate-limited requests */
    public static final int MAX_RETRIES = 2;
    /** Maximum retries on conflicting writes */
    public static final int MAX_CONFLICT_RETRIES = 3;
    /** Delay before the first conflict retry, multiplied by the attempt number on subsequent ones */
    public static final long CONFLICT_RETRY_DELAY_MILLIS = 200;
    /** Commits requested per page when walking a file's history */
    public static final int COMMITS_PER_PAGE = 100;
    /** Maximum history pages retrieved, bounding the API calls a single TimeMap request can make */
    public static final int MAX_COMMIT_PAGES = 10;

    private final WebTarget endpoint;
    private final String authorization;
    private final String owner, repo, branch;

    /** Result of a file commit: the commit SHA and the file's new blob SHA */
    public record Commit(String commitSha, String blobSha) { }

    /**
     * Constructs a client for one repository branch.
     *
     * @param client HTTP client (must perform standard TLS server verification)
     * @param apiBase API base URI (<code>https://api.github.com</code> in production, overridable for tests)
     * @param token access token
     * @param owner repository owner
     * @param repo repository name
     * @param branch branch name
     */
    public GitHubClient(Client client, URI apiBase, String token, String owner, String repo, String branch)
    {
        this.endpoint = client.target(apiBase);
        this.authorization = "Bearer " + token;
        this.owner = owner;
        this.repo = repo;
        this.branch = branch;
    }

    /**
     * Creates or updates a file on the branch.
     * The current blob SHA is fetched first, as the Contents API requires it for updates (optimistic locking);
     * a conflicting write is retried with a re-read SHA, up to {@link #MAX_CONFLICT_RETRIES} times.
     *
     * @param path file path within the repository
     * @param content file content
     * @param message commit message
     * @param authorName commit author name (the agent's WebID)
     * @return commit and blob SHAs
     */
    public Commit putFile(String path, byte[] content, String message, String authorName)
    {
        for (int attempt = 0; ; attempt++)
        {
            Optional<String> sha = getFileSha(path); // re-probed on every attempt: a conflict means this SHA has moved

            JsonObjectBuilder builder = Json.createObjectBuilder().
                add("message", message).
                add("content", Base64.getEncoder().encodeToString(content)).
                add("branch", branch).
                add("author", author(authorName));
            sha.ifPresent(s -> builder.add("sha", s));
            JsonObject json = builder.build(); // built once: a builder yields its object only to the first build()

            try (Response response = invoke(() -> contents(path).
                    request(GITHUB_JSON).
                    header(HttpHeaders.AUTHORIZATION, authorization).
                    buildPut(Entity.entity(json, MediaType.APPLICATION_JSON_TYPE))))
            {
                if (response.getStatus() == Response.Status.OK.getStatusCode() || response.getStatus() == Response.Status.CREATED.getStatusCode())
                {
                    JsonObject result = response.readEntity(JsonObject.class);
                    return new Commit(result.getJsonObject("commit").getString("sha"), result.getJsonObject("content").getString("sha"));
                }

                if (response.getStatus() == Response.Status.CONFLICT.getStatusCode() && attempt < MAX_CONFLICT_RETRIES)
                {
                    backOff(attempt, path);
                    continue;
                }

                throw new RuntimeException("GitHub commit of '" + path + "' to " + owner + "/" + repo + " failed with status " + response.getStatus());
            }
        }
    }

    /**
     * Deletes a file from the branch. A no-op if the file does not exist.
     * A conflicting write is retried with a re-read SHA, up to {@link #MAX_CONFLICT_RETRIES} times.
     *
     * @param path file path within the repository
     * @param message commit message
     * @param authorName commit author name (the agent's WebID)
     */
    public void deleteFile(String path, String message, String authorName)
    {
        for (int attempt = 0; ; attempt++)
        {
            Optional<String> sha = getFileSha(path); // re-probed on every attempt: a conflict means this SHA has moved
            if (sha.isEmpty())
            {
                if (log.isDebugEnabled()) log.debug("File '{}' not found in {}/{}, nothing to delete", path, owner, repo);
                return;
            }

            JsonObject json = Json.createObjectBuilder().
                add("message", message).
                add("sha", sha.get()).
                add("branch", branch).
                add("author", author(authorName)).
                build();

            try (Response response = invoke(() -> contents(path).
                    request(GITHUB_JSON).
                    property(ClientProperties.SUPPRESS_HTTP_COMPLIANCE_VALIDATION, true). // the Contents API requires a body on DELETE
                    header(HttpHeaders.AUTHORIZATION, authorization).
                    build("DELETE", Entity.entity(json, MediaType.APPLICATION_JSON_TYPE))))
            {
                if (response.getStatus() == Response.Status.OK.getStatusCode()) return;

                if (response.getStatus() == Response.Status.CONFLICT.getStatusCode() && attempt < MAX_CONFLICT_RETRIES)
                {
                    backOff(attempt, path);
                    continue;
                }

                throw new RuntimeException("GitHub deletion of '" + path + "' from " + owner + "/" + repo + " failed with status " + response.getStatus());
            }
        }
    }

    /**
     * Retrieves raw file content at a given commit.
     *
     * @param path file path within the repository
     * @param ref commit SHA (or any git ref)
     * @return file content, or empty if not found at that ref
     */
    public Optional<byte[]> getFileAtCommit(String path, String ref)
    {
        try (Response response = invoke(() -> contents(path).queryParam("ref", ref).
                request(GITHUB_RAW).
                header(HttpHeaders.AUTHORIZATION, authorization).
                buildGet()))
        {
            if (response.getStatus() == Response.Status.OK.getStatusCode()) return Optional.of(response.readEntity(byte[].class));
            if (response.getStatus() == Response.Status.NOT_FOUND.getStatusCode()) return Optional.empty();

            throw new RuntimeException("GitHub retrieval of '" + path + "' at '" + ref + "' from " + owner + "/" + repo + " failed with status " + response.getStatus());
        }
    }

    /** A commit in a file's history: SHA, datetime, author name */
    public record CommitInfo(String sha, Instant datetime, String authorName) { }

    /**
     * Lists commits that touched a file on the branch, most recent first.
     * Pages through the history so the result is the file's complete history, up to
     * {@link #MAX_COMMIT_PAGES} pages.
     *
     * @param path file path within the repository
     * @return commit list, empty if the file has no history
     */
    public List<CommitInfo> listCommits(String path)
    {
        List<CommitInfo> commits = new ArrayList<>();

        for (int page = 1; page <= MAX_COMMIT_PAGES; page++)
        {
            final int currentPage = page;
            try (Response response = invoke(() -> endpoint.path("repos/{owner}/{repo}/commits").
                    queryParam("path", path).
                    queryParam("sha", branch).
                    queryParam("per_page", COMMITS_PER_PAGE).
                    queryParam("page", currentPage).
                    resolveTemplate("owner", owner).resolveTemplate("repo", repo).
                    request(GITHUB_JSON).
                    header(HttpHeaders.AUTHORIZATION, authorization).
                    buildGet()))
            {
                if (response.getStatus() != Response.Status.OK.getStatusCode()) return commits;

                JsonArray array = response.readEntity(JsonArray.class);
                for (JsonValue value : array)
                {
                    JsonObject commit = value.asJsonObject();
                    JsonObject author = commit.getJsonObject("commit").getJsonObject("author");
                    commits.add(new CommitInfo(commit.getString("sha"), Instant.parse(author.getString("date")), author.getString("name")));
                }

                if (array.size() < COMMITS_PER_PAGE) return commits; // last page
            }
        }

        // the history is longer than we retrieve, so the oldest commit returned is not the file's first
        if (log.isWarnEnabled()) log.warn("History of '{}' in {}/{} exceeds {} commits, TimeMap is truncated to the most recent ones",
            path, owner, repo, MAX_COMMIT_PAGES * COMMITS_PER_PAGE);

        return commits;
    }

    /**
     * Returns the committer datetime of a commit.
     *
     * @param sha commit SHA
     * @return commit datetime, or empty if the commit is not found
     */
    public Optional<Instant> getCommitDate(String sha)
    {
        try (Response response = invoke(() -> endpoint.path("repos/{owner}/{repo}/commits/{sha}").
                resolveTemplate("owner", owner).resolveTemplate("repo", repo).resolveTemplate("sha", sha).
                request(GITHUB_JSON).
                header(HttpHeaders.AUTHORIZATION, authorization).
                buildGet()))
        {
            if (response.getStatus() != Response.Status.OK.getStatusCode()) return Optional.empty();

            JsonObject result = response.readEntity(JsonObject.class);
            String date = result.getJsonObject("commit").getJsonObject("committer").getString("date");
            return Optional.of(Instant.parse(date));
        }
    }

    /**
     * Returns the current blob SHA of a file on the branch.
     *
     * @param path file path within the repository
     * @return blob SHA, or empty if the file does not exist
     */
    public Optional<String> getFileSha(String path)
    {
        try (Response response = invoke(() -> contents(path).queryParam("ref", branch).
                request(GITHUB_JSON).
                header(HttpHeaders.AUTHORIZATION, authorization).
                buildGet()))
        {
            if (response.getStatus() == Response.Status.OK.getStatusCode()) return Optional.of(response.readEntity(JsonObject.class).getString("sha"));

            return Optional.empty();
        }
    }

    /**
     * Returns the repository owner.
     *
     * @return owner name
     */
    public String getOwner()
    {
        return owner;
    }

    /**
     * Returns the repository name.
     *
     * @return repository name
     */
    public String getRepo()
    {
        return repo;
    }

    /**
     * Returns the branch that commits are made on.
     *
     * @return branch name
     */
    public String getBranch()
    {
        return branch;
    }

    private WebTarget contents(String path)
    {
        return endpoint.path("repos/{owner}/{repo}/contents/{path}").
            resolveTemplate("owner", owner).
            resolveTemplate("repo", repo).
            resolveTemplate("path", path, false); // do not encode slashes in the path
    }

    private JsonObject author(String name)
    {
        return Json.createObjectBuilder().add("name", name).add("email", AUTHOR_EMAIL).build();
    }

    /**
     * Invokes a request, retrying a bounded number of times when GitHub rate-limits it (429, or 403 with <code>Retry-After</code>).
     */
    private Response invoke(Supplier<Invocation> invocation)
    {
        Response response = invocation.get().invoke();

        for (int retry = 0; retry < MAX_RETRIES && isRateLimited(response); retry++)
        {
            long delaySeconds = retryAfter(response);
            response.close();
            if (log.isWarnEnabled()) log.warn("GitHub rate limit hit on {}/{}, retrying after {}s", owner, repo, delaySeconds);

            try
            {
                Thread.sleep(delaySeconds * 1000);
            }
            catch (InterruptedException ex)
            {
                Thread.currentThread().interrupt();
                throw new RuntimeException(ex);
            }

            response = invocation.get().invoke();
        }

        return response;
    }

    private boolean isRateLimited(Response response)
    {
        if (response.getStatus() == 429) return true;

        return response.getStatus() == Response.Status.FORBIDDEN.getStatusCode() &&
            (response.getHeaderString("Retry-After") != null || "0".equals(response.getHeaderString("x-ratelimit-remaining")));
    }

    /**
     * Sleeps before retrying a write that conflicted, backing off linearly to give the competing writer time to finish.
     */
    private void backOff(int attempt, String path)
    {
        if (log.isWarnEnabled()) log.warn("Conflicting write of '{}' to {}/{} on branch '{}', retrying", path, owner, repo, branch);

        try
        {
            Thread.sleep(CONFLICT_RETRY_DELAY_MILLIS * (attempt + 1));
        }
        catch (InterruptedException ex)
        {
            Thread.currentThread().interrupt();
            throw new RuntimeException(ex);
        }
    }

    private long retryAfter(Response response)
    {
        String retryAfter = response.getHeaderString("Retry-After");
        if (retryAfter != null)
            try
            {
                return Math.min(Long.parseLong(retryAfter), 60);
            }
            catch (NumberFormatException ex) { }

        return 5;
    }

}
