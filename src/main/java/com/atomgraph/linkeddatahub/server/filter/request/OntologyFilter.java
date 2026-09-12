/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.linkeddatahub.server.util.ScopedGraphRepository;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.server.exception.OntologyException;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Optional;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import org.apache.jena.graph.Graph;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.graph.Triple;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.UnionGraph;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.ontapi.utils.Graphs;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.apache.jena.vocabulary.OWL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that retrieves the application ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(800)
public class OntologyFilter implements ContainerRequestFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(OntologyFilter.class);

    /**
     * Paths that should not trigger ontology loading to avoid circular dependencies.
     *
     * When an ontology contains owl:imports pointing to URIs within these paths,
     * loading the ontology would trigger HTTP requests to those URIs. If those requests
     * are intercepted by this filter, it creates a circular dependency:
     *
     * 1. Request arrives for /uploads/xyz
     * 2. OntologyFilter intercepts it and loads ontology
     * 3. Ontology has owl:imports for /uploads/xyz
     * 4. Jena FileManager makes HTTP request to /uploads/xyz
     * 5. OntologyFilter intercepts it again → infinite loop/deadlock
     *
     * Additionally, uploaded files are binary/RDF content that don't require
     * ontology context for their serving logic.
     */
    private static final java.util.Set<String> IGNORED_PATH_PREFIXES = java.util.Set.of(
        "uploads/"
    );

    @Inject com.atomgraph.linkeddatahub.Application system;

    
    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        String path = crc.getUriInfo().getPath();

        // Skip ontology loading for paths that may be referenced in owl:imports
        // to prevent circular dependency deadlocks during ontology resolution
        if (IGNORED_PATH_PREFIXES.stream().anyMatch(path::startsWith))
        {
            if (log.isTraceEnabled()) log.trace("Skipping ontology loading for path: {}", path);
            crc.setProperty(OWL.Ontology.getURI(), Optional.empty());
            return;
        }

        crc.setProperty(OWL.Ontology.getURI(), getOntology(crc));
    }
    
    /**
     * Retrieves (optional) ontology from the container request context.
     *
     * @param crc request context
     * @return optional ontology
     */
    public Optional<OntModel> getOntology(ContainerRequestContext crc)
    {
        Optional<Application> appOpt = getApplication(crc);

        if (!appOpt.isPresent()) return Optional.empty();

        try
        {
            return Optional.ofNullable(getOntology(appOpt.get()));
        }
        catch (OntologyException ex)
        {
            return Optional.empty();
        }
    }

    /**
     * Gets ontology of the specified application.
     *
     * @param app application resource
     * @return ontology model
     */
    public OntModel getOntology(Application app)
    {
        if (app.getOntology() == null) return null;

        return getOntology(app, app.getOntology().getURI());
    }

    /**
     * Returns the ontology model for the specified ontology URI, assembling its owl:imports closure
     * on a cache miss. The returned model is a fresh per-request wrapper over the shared closure
     * union graph.
     *
     * @param app application resource
     * @param uri ontology URI
     * @return ontology model
     */
    public OntModel getOntology(Application app, String uri)
    {
        if (app == null) throw new IllegalArgumentException("Application cannot be null");
        if (uri == null) throw new IllegalArgumentException("Ontology URI cannot be null");

        final PrefixGraphRepository repository = app.canAs(EndUserApplication.class) ?
            getSystem().getRepository(app.as(EndUserApplication.class)) : getSystem().getRepository();

        // only assemble the closure if it is not already cached; the double check under the repository
        // lock ensures a single thread assembles it (loadOntology is a compound load + union build, not
        // atomic), so concurrent cold requests don't duplicate the work or race each other's writes
        UnionGraph union = getSystem().getOntologyGraphs().get(uri);
        if (union == null)
        {
            synchronized (repository)
            {
                union = getSystem().getOntologyGraphs().get(uri);
                if (union == null)
                {
                    union = loadOntology(repository, uri, getSystem().getPackageOntologies(app));
                    getSystem().getOntologyGraphs().put(uri, union);
                }
            }
        }

        return OntModelFactory.createModel(union, OntSpecification.OWL2_FULL_MEM);
    }

    /**
     * Assembles the ontology's owl:imports closure composed with the ontologies of the imported
     * packages. Each package ontology is declared as an owl:imports of the application ontology, and
     * ontapi resolves it — along with its own transitive imports — as part of the closure, through the
     * same scoped repository view as every other import. The declaration is derived from the
     * application's ldh:import data on every load and never persisted, so the ldh:import triples remain
     * the single source of truth. A package ontology that cannot be resolved is skipped so a broken
     * package cannot take the application ontology down.
     *
     * @param repository graph repository
     * @param uri ontology URI
     * @param packageOntologies package ontology URIs
     * @return closure union graph
     */
    public static UnionGraph loadOntology(PrefixGraphRepository repository, String uri, List<URI> packageOntologies)
    {
        if (!packageOntologies.isEmpty()) declarePackageImports(repository, uri, packageOntologies);

        return loadOntology(repository, uri);
    }

    /**
     * Declares the package ontologies as owl:imports of the application ontology on its base graph, so
     * that ontapi pulls them into the imports closure when the model is constructed.
     * <p>
     * The declaration is additive: {@code ClearOntology} evicts the raw graph before every reload, so an
     * uninstalled package's import cannot survive in the cached copy. A reload path that skipped that
     * eviction would need this to reconcile against {@code packageOntologies} rather than only add.
     *
     * @param repository graph repository
     * @param uri ontology URI
     * @param packageOntologies package ontology URIs
     */
    public static void declarePackageImports(PrefixGraphRepository repository, String uri, List<URI> packageOntologies)
    {
        Graph base = repository.get(uri);
        Optional<Node> name = Graphs.findOntologyNameNode(base);
        if (name.isEmpty())
        {
            if (log.isErrorEnabled()) log.error("Ontology with URI '{}' carries no ontology header, cannot import packages {} into it", uri, packageOntologies);
            return;
        }

        for (URI packageOntology : packageOntologies)
        {
            // the model is constructed with ignoreUnresolvedImports, which silently substitutes an empty
            // graph for an import it cannot resolve — resolve it here so that a broken package is reported
            // instead of composing as nothing
            if (!isResolvable(repository, packageOntology.toString()))
            {
                if (log.isErrorEnabled()) log.error("Could not load package ontology '{}', skipping it", packageOntology);
                continue;
            }

            base.add(Triple.create(name.get(), OWL.imports.asNode(), NodeFactory.createURI(packageOntology.toString())));
        }
    }

    /**
     * Returns true if the repository can supply a graph for the given ID.
     *
     * @param repository graph repository
     * @param id graph ID
     * @return true if resolvable
     */
    public static boolean isResolvable(PrefixGraphRepository repository, String id)
    {
        try
        {
            return repository.get(id) != null;
        }
        catch (RuntimeException ex) // unmapped location, 404, connection refused, unparseable document...
        {
            if (log.isDebugEnabled()) log.debug("Could not resolve graph with ID '{}'", id, ex);
            return false;
        }
    }

    /**
     * Assembles the ontology's owl:imports closure as a union graph. ontapi resolves the closure through
     * a scoped repository view: raw per-document graphs are read through (and cached in) the shared
     * repository, while ontapi's union-graph bookkeeping stays local to the view — the shared repository
     * keeps serving raw document graphs, and duplicate ontology IDs across applications cannot collide.
     * No inference is applied: all consumers traverse class/property hierarchies explicitly.
     *
     * @param repository graph repository
     * @param uri ontology URI
     * @return closure union graph
     */
    public static UnionGraph loadOntology(PrefixGraphRepository repository, String uri)
    {
        if (log.isDebugEnabled()) log.debug("Started loading ontology with URI '{}'", uri);
        ScopedGraphRepository scoped = new ScopedGraphRepository(repository);
        OntModel ontology = OntModelFactory.createModel(repository.get(uri), OntSpecification.OWL2_FULL_MEM, scoped);
        UnionGraph union = (UnionGraph)ontology.getGraph();
        // promote rdfs:Class to owl:Class so the OWL2 profile recognises third-party vocab terms (e.g. sp:Describe
        // in sp.ttl) as named classes. The promotions live in their own union member so no document graph is
        // polluted; carrying no owl:Ontology header, the member is ignored by ontapi's union-graph listener
        Model promotions = ModelFactory.createDefaultModel();
        ontology.listSubjectsWithProperty(RDF.type, RDFS.Class).forEach(r -> promotions.add(r, RDF.type, OWL.Class));
        if (!promotions.isEmpty()) union.addSubGraph(promotions.getGraph());
        // cache closure graphs under their fragment-stripped document URIs too. ontapi keys imports under
        // their declared ontology IRIs, which need not be repository entries (a content-addressed upload is
        // cached under its uploads/ URI while declaring a foreign ontology IRI) — only alias ids the shared
        // repository actually holds, lest the lookup dereference a foreign IRI over HTTP
        scoped.ids().filter(closureURI -> closureURI.startsWith("http://") || closureURI.startsWith("https://")).
            filter(repository::isCached).
            forEach(closureURI -> addDocumentModel(repository, closureURI));
        if (log.isDebugEnabled()) log.debug("Finished loading ontology with URI '{}'", uri);
        return union;
    }

    /**
     * Caches an imported graph under its fragment-stripped document URI as a secondary cache key.
     *
     * @param repository graph repository
     * @param importURI ontology URI
     */
    public static void addDocumentModel(PrefixGraphRepository repository, String importURI)
    {
        try
        {
            URI ontologyURI = URI.create(importURI);
            // remove fragment and normalize
            URI docURI = new URI(ontologyURI.getScheme(), ontologyURI.getSchemeSpecificPart(), null).normalize();
            // only cache the document URI if it is not already cached or mapped to a different location
            if (!repository.isCached(docURI.toString()) && repository.resolve(docURI.toString()).equals(docURI.toString()))
                repository.put(docURI.toString(), repository.get(importURI));
        }
        catch (URISyntaxException ex)
        {
            throw new RuntimeException(ex);
        }
    }
    
    /**
     * Retrieves application from the container request context.
     *
     * @param crc request context
     * @return optional application resource
     */
    public Optional<Application> getApplication(ContainerRequestContext crc)
    {
        return ((Optional<Application>)crc.getProperty(LAPP.Application.getURI()));
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application.
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
