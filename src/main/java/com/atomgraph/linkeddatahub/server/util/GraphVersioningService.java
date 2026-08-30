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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.core.vocabulary.A;
import com.atomgraph.linkeddatahub.client.GitHubClient;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import com.atomgraph.linkeddatahub.vocabulary.GitHub;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.client.Client;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.sparql.vocabulary.DOAP;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Mirrors named graphs of versioning-enabled applications into GitHub repositories.
 * The unit of work is reconciliation: a task re-reads the graph from the application's
 * SPARQL service at execution time and makes the repository file match — including deleting
 * the file when the graph is gone. Tasks for the same file are chained sequentially so
 * commits never race the GitHub Contents API's SHA-based optimistic locking.
 * Versioning is best-effort: task failures are logged, never propagated.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphVersioningService
{

    private static final Logger log = LoggerFactory.getLogger(GraphVersioningService.class);

    /** Auth token property (established by <code>select-root-services.rq</code>; Core's A vocabulary class lacks the constant) */
    public static final Property authToken = ResourceFactory.createProperty(A.NS + "authToken");

    /** Per-repository client and file path prefix */
    public record Repository(GitHubClient client, String pathPrefix) { }

    private final Map<String, Repository> repositories;
    private final Map<String, CompletableFuture<Void>> commitChains = new ConcurrentHashMap<>();
    private final ExecutorService executor = Executors.newFixedThreadPool(4);

    /**
     * Builds the per-application repository map from the context model.
     * Applications without a <code>lapp:versioningRepository</code> are not versioned.
     *
     * @param contextModel union model of the context dataset
     * @param client HTTP client with standard TLS server verification
     */
    public GraphVersioningService(Model contextModel, Client client)
    {
        repositories = new HashMap<>();

        StmtIterator it = contextModel.listStatements(null, LAPP.versioningRepository, (org.apache.jena.rdf.model.RDFNode)null);
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.nextStatement();
                Resource app = stmt.getSubject();
                Resource repo = stmt.getResource();

                Repository repository = repository(app, repo, client);
                if (repository != null) repositories.put(app.getURI(), repository);
            }
        }
        finally
        {
            it.close();
        }
    }

    private Repository repository(Resource app, Resource repo, Client client)
    {
        if (!repo.hasProperty(DOAP.location) || !repo.hasProperty(authToken))
        {
            if (log.isWarnEnabled()) log.warn("Versioning repository of application <{}> is missing doap:location or a:authToken, versioning disabled for it", app.getURI());
            return null;
        }

        URI location = URI.create(repo.getPropertyResourceValue(DOAP.location).getURI());
        String[] segments = location.getPath().substring(1).split("/");
        if (segments.length != 2)
        {
            if (log.isWarnEnabled()) log.warn("Versioning repository location <{}> of application <{}> is not an owner/repository URL, versioning disabled for it", location, app.getURI());
            return null;
        }

        String token = repo.getProperty(authToken).getString();
        String branch = repo.hasProperty(GitHub.branch) ? repo.getProperty(GitHub.branch).getString() : "main";
        String pathPrefix = repo.hasProperty(GitHub.pathPrefix) ? repo.getProperty(GitHub.pathPrefix).getString() : "graphs";

        if (log.isInfoEnabled()) log.info("Graph versioning enabled for application <{}> into {} (branch '{}', path prefix '{}')", app.getURI(), location, branch, pathPrefix);
        return new Repository(new GitHubClient(client, GitHubClient.API_BASE, token, segments[0], segments[1], branch), pathPrefix);
    }

    /**
     * Returns the repository configured for an application, if any.
     *
     * @param appURI application URI
     * @return repository, or empty if the application is not versioned
     */
    public Optional<Repository> getRepository(String appURI)
    {
        return Optional.ofNullable(repositories.get(appURI));
    }

    /**
     * Schedules asynchronous reconciliation of a graph's repository file with its current store state.
     * Chained per file path; returns immediately.
     *
     * @param serviceContext deployment context of the application's SPARQL service
     * @param appURI application URI
     * @param appBase application base URI
     * @param graphURI graph (document) URI
     * @param agentWebID WebID of the agent whose write triggered the commit (author of the commit)
     * @param method HTTP method of the triggering request (part of the commit message)
     */
    public void commitAsync(ServiceContext serviceContext, String appURI, URI appBase, URI graphURI, String agentWebID, String method)
    {
        Repository repository = repositories.get(appURI);
        if (repository == null) return;

        String path = path(repository.pathPrefix(), appBase, graphURI);
        String message = method + " " + graphURI;

        commitChains.compute(path, (key, chain) ->
        {
            CompletableFuture<Void> previous = chain != null ? chain : CompletableFuture.completedFuture(null);
            CompletableFuture<Void> next = previous.thenRunAsync(() -> reconcile(serviceContext, repository, path, graphURI, message, agentWebID), executor).
                exceptionally(ex ->
                {
                    if (log.isErrorEnabled()) log.error("Failed to version graph <{}> as '{}': {}", graphURI, path, ex.getMessage());
                    return null;
                });
            next.whenComplete((result, ex) -> commitChains.remove(key, next));
            return next;
        });
    }

    private void reconcile(ServiceContext serviceContext, Repository repository, String path, URI graphURI, String message, String agentWebID)
    {
        Model model;
        try
        {
            model = serviceContext.getGraphStoreClient().getModel(graphURI.toString());
        }
        catch (NotFoundException ex)
        {
            repository.client().deleteFile(path, message, agentWebID);
            if (log.isDebugEnabled()) log.debug("Deleted '{}' (graph <{}> is gone)", path, graphURI);
            return;
        }

        GitHubClient.Commit commit = repository.client().putFile(path, toSortedNTriples(model), message, agentWebID);
        if (log.isDebugEnabled()) log.debug("Committed graph <{}> as '{}': {}", graphURI, path, commit.commitSha());
    }

    /**
     * Retrieves a graph's state at a given commit.
     *
     * @param appURI application URI
     * @param appBase application base URI
     * @param graphURI graph (document) URI
     * @param ref commit SHA
     * @return the graph model with its blob SHA, or empty if not versioned at that commit
     */
    public Optional<Version> getVersion(String appURI, URI appBase, URI graphURI, String ref)
    {
        Repository repository = repositories.get(appURI);
        if (repository == null) return Optional.empty();

        String path = path(repository.pathPrefix(), appBase, graphURI);
        return repository.client().getFileAtCommit(path, ref).map(content ->
        {
            Model model = ModelFactory.createDefaultModel();
            RDFDataMgr.read(model, new ByteArrayInputStream(content), graphURI.toString(), Lang.NTRIPLES);
            return new Version(model, repository.client().getCommitDate(ref).orElse(null));
        });
    }

    /** A historical graph version: the model and the commit datetime */
    public record Version(Model model, Instant datetime) { }

    /**
     * Selects the graph's Memento for a requested datetime, as a TimeGate does.
     *
     * @param appURI application URI
     * @param appBase application base URI
     * @param graphURI graph (document) URI
     * @param datetime the requested datetime, or null for the most recent Memento
     * @return the selected commit, or empty if the application is not versioned or the graph has no history
     */
    public Optional<GitHubClient.CommitInfo> getMemento(String appURI, URI appBase, URI graphURI, Instant datetime)
    {
        Repository repository = repositories.get(appURI);
        if (repository == null) return Optional.empty();

        String path = path(repository.pathPrefix(), appBase, graphURI);
        return selectMemento(repository.client().listCommits(path), datetime);
    }

    /**
     * Selects the commit closest in time to a requested datetime.
     * RFC 7089 leaves the algorithm to the server but requires it to be consistent: this one takes the
     * smallest absolute distance, resolving ties towards the more recent Memento. With no datetime
     * requested the most recent Memento is selected.
     *
     * @param commits commit history, most recent first
     * @param datetime the requested datetime, or null for the most recent commit
     * @return the selected commit, or empty if there is no history
     */
    public static Optional<GitHubClient.CommitInfo> selectMemento(List<GitHubClient.CommitInfo> commits, Instant datetime)
    {
        if (commits.isEmpty()) return Optional.empty();
        if (datetime == null) return Optional.of(commits.get(0));

        // min() keeps the first of equally distant commits, and the most recent one comes first
        return commits.stream().min(Comparator.comparing(commit -> Duration.between(commit.datetime(), datetime).abs()));
    }

    /**
     * Retrieves a graph's version history as a TimeMap model.
     *
     * @param appURI application URI
     * @param appBase application base URI
     * @param graphURI graph (document) URI
     * @return TimeMap model, or empty if the application is not versioned or the graph has no history
     */
    public Optional<Model> getTimeMap(String appURI, URI appBase, URI graphURI)
    {
        Repository repository = repositories.get(appURI);
        if (repository == null) return Optional.empty();

        String path = path(repository.pathPrefix(), appBase, graphURI);
        List<GitHubClient.CommitInfo> commits = repository.client().listCommits(path);
        // a TimeMap is a list of Mementos; without any, there is no history to describe and the Original Resource
        // would not be derivable from the model either (it is reached through prov:specializationOf)
        if (commits.isEmpty()) return Optional.empty();

        return Optional.of(toTimeMap(graphURI, commits));
    }

    /**
     * Builds a TimeMap model from a graph's commit history, described with PROV-O.
     * The TimeMap is a <code>prov:Collection</code> of Mementos, each a <code>prov:Entity</code> that is a
     * <code>prov:specializationOf</code> the Original Resource. Memento URIs use the <code>version</code>
     * query parameter with the commit SHA.
     *
     * @param graphURI graph (document) URI
     * @param commits commit history, most recent first
     * @return TimeMap model
     */
    public static Model toTimeMap(URI graphURI, List<GitHubClient.CommitInfo> commits)
    {
        Model model = ModelFactory.createDefaultModel();
        Resource original = model.createResource(graphURI.toString());
        Resource timeMap = model.createResource(graphURI + "?timemap").
            addProperty(RDF.type, PROV.Collection);

        Resource successor = null; // the memento of the next-more-recent commit that touched this file
        for (GitHubClient.CommitInfo commit : commits)
        {
            Resource memento = model.createResource(graphURI + "?version=" + commit.sha()).
                addProperty(RDF.type, PROV.Entity).
                addProperty(PROV.specializationOf, original).
                addProperty(PROV.generatedAtTime, model.createTypedLiteral(commit.datetime().toString(), XSDDatatype.XSDdateTime));
            if (isAbsoluteURI(commit.authorName())) memento.addProperty(DCTerms.creator, model.createResource(commit.authorName()));

            timeMap.addProperty(PROV.hadMember, memento);
            // the commit list is filtered by path, so adjacent entries are adjacent revisions of this graph
            // (unlike git parents, which are repository-wide and usually did not touch the file)
            if (successor != null) successor.addProperty(PROV.wasRevisionOf, memento);
            successor = memento;
        }

        return model;
    }

    private static boolean isAbsoluteURI(String string)
    {
        if (string == null) return false;

        try
        {
            return new URI(string).isAbsolute();
        }
        catch (URISyntaxException ex)
        {
            return false;
        }
    }

    /**
     * Maps a graph URI to its repository file path.
     *
     * @param pathPrefix repository path prefix
     * @param base application base URI
     * @param graphURI graph URI
     * @return file path
     */
    public static String path(String pathPrefix, URI base, URI graphURI)
    {
        String relative = base.relativize(graphURI).getPath();
        if (relative.isEmpty()) relative = "root"; // the app base document itself
        if (relative.endsWith("/")) relative = relative.substring(0, relative.length() - 1);

        return pathPrefix + "/" + relative + ".nt";
    }

    /**
     * Serializes a model as N-Triples with sorted lines, so successive serializations
     * of the same graph are byte-identical and git diffs are minimal.
     *
     * @param model the model
     * @return sorted N-Triples bytes
     */
    public static byte[] toSortedNTriples(Model model)
    {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        RDFDataMgr.write(out, model, Lang.NTRIPLES);

        String[] lines = out.toString(StandardCharsets.UTF_8).split("\n");
        Arrays.sort(lines);

        StringBuilder sorted = new StringBuilder();
        for (String line : lines)
            if (!line.isBlank()) sorted.append(line.stripTrailing()).append('\n');

        return sorted.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Shuts down the background executor.
     */
    public void shutdown()
    {
        executor.shutdown();
    }

}
