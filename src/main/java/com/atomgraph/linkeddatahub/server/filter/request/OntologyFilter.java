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
import org.apache.jena.graph.Graph;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntID;
import org.apache.jena.ontapi.model.OntModel;
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

        // only build the inferred model if the ontology is not already cached
        if (!repository.isCached(uri))
        {
            if (log.isDebugEnabled()) log.debug("Started loading ontology with URI '{}'", uri);
            Graph baseGraph = repository.get(uri); // end-user: SPARQL-first; otherwise bundled mapping / HTTP
            OntModel inferred = OntModelFactory.createModel(baseGraph, OntSpecification.OWL2_DL_MEM_RDFS_INF, repository);
            // materialize inferences to avoid invoking the rules engine on every request
            OntModel materialized = OntModelFactory.createModel(OntSpecification.OWL2_DL_MEM);
            materialized.add(inferred);
            repository.put(uri, materialized.getGraph());
            // cache imported graphs under their (fragment-stripped) document URIs too
            importClosure(inferred, new HashSet<>()).forEach(importURI -> addDocumentModel(repository, importURI));
            if (log.isDebugEnabled()) log.debug("Finished loading ontology with URI '{}'", uri);
        }

        return OntModelFactory.createModel(repository.get(uri), OntSpecification.OWL2_DL_MEM, repository);
    }

    /**
     * Collects the transitive owl:imports closure URIs of the given ontology model.
     *
     * @param model ontology model
     * @param seen accumulator of already-visited import URIs
     * @return the import closure URIs
     */
    public static Set<String> importClosure(OntModel model, Set<String> seen)
    {
        model.imports().forEach(imp -> imp.id().map(OntID::getURI).ifPresent(importURI ->
        {
            if (seen.add(importURI)) importClosure(imp, seen);
        }));
        return seen;
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
