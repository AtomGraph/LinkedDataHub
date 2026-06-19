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
import com.atomgraph.core.util.jena.PrefixGraphRepository;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.server.exception.OntologyException;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
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
     * Loads the ontology model for the specified ontology URI, building its owl:imports closure with
     * RDFS inference and materializing the inferences into the repository cache.
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

        // only build the materialized model if the ontology is not already cached
        if (!repository.isCached(uri)) loadOntology(repository, uri);

        return OntModelFactory.createModel(repository.get(uri), OntSpecification.OWL2_FULL_MEM);
    }

    /**
     * Builds and caches the materialized ontology model. Assembles the owl:imports closure into a single
     * graph (so ontapi never manages a union-graph hierarchy over the shared repository), applies RDFS
     * inference over the flattened closure, and materializes the inferences into the repository cache so
     * the rules engine is not invoked on every request.
     *
     * @param repository graph repository
     * @param uri ontology URI
     */
    public static void loadOntology(PrefixGraphRepository repository, String uri)
    {
        if (log.isDebugEnabled()) log.debug("Started loading ontology with URI '{}'", uri);
        Model union = ModelFactory.createDefaultModel();
        Set<String> closure = new HashSet<>();
        loadClosure(repository, uri, union, closure);
        OntModel inferred = OntModelFactory.createModel(union.getGraph(), OntSpecification.OWL2_FULL_MEM_RDFS_INF);
        OntModel materialized = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);
        materialized.add(inferred);
        repository.put(uri, materialized.getGraph());
        // cache imported graphs under their fragment-stripped document URIs too
        closure.stream().filter(closureURI -> !closureURI.equals(uri)).forEach(importURI -> addDocumentModel(repository, importURI));
        if (log.isDebugEnabled()) log.debug("Finished loading ontology with URI '{}'", uri);
    }

    /**
     * Recursively loads the transitive owl:imports closure of an ontology into a single union model,
     * fetching each graph via the repository (SPARQL-first / bundled mappings).
     *
     * @param repository graph repository
     * @param uri ontology URI
     * @param union accumulator model
     * @param seen accumulator of visited URIs (prevents cycles)
     */
    public static void loadClosure(PrefixGraphRepository repository, String uri, Model union, Set<String> seen)
    {
        if (!seen.add(uri)) return;
        Model model = ModelFactory.createModelForGraph(repository.get(uri));
        union.add(model);
        model.listObjectsOfProperty(OWL.imports).toList().forEach(imp ->
        {
            if (imp.isURIResource()) loadClosure(repository, imp.asResource().getURI(), union, seen);
        });
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
