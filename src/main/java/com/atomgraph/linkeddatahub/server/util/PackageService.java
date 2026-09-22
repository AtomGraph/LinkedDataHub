/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import org.apache.jena.enhanced.UnsupportedPolymorphismException;
import org.apache.jena.graph.Graph;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Resolves the packages an application imports and the artifacts they deliver.
 *
 * An application declares an import with a single <code>ldh:import</code> triple; everything else about a
 * package - its ontology, its stylesheet - is read from the package's own Linked Data description. The
 * traversal from the import set to those descriptions is the same whichever artifact the caller is after,
 * so it lives here once and each caller plucks the property it needs from {@link #getPackages}.
 *
 * The service also materializes package ontologies. A package delivers its ontology rather than the
 * application owning it, so its constructors cannot be edited where they are: the copy this makes is the
 * application's own annotation document over the same vocabulary, which is editable like any other.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class PackageService
{

    private static final Logger log = LoggerFactory.getLogger(PackageService.class);

    /** Path of the ontologies container in the admin application. */
    public static final String ONTOLOGIES_PATH = "ontologies/";

    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs the service from the system application, whose repository, service contexts and HTTP
     * client it resolves packages through.
     *
     * @param system system application
     */
    public PackageService(com.atomgraph.linkeddatahub.Application system)
    {
        this.system = system;
    }

    /**
     * Returns the URIs of the packages an application imports, ordered. Reads the declared import set only:
     * no description is resolved, which is what makes this usable as a cache key for the composed stylesheet
     * without the key itself costing a round trip per package.
     *
     * @param app application resource
     * @return list of package URIs
     */
    public List<URI> getPackageURIs(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return app.getImportedPackages().stream().
            filter(Resource::isURIResource).
            map(pkg -> URI.create(pkg.getURI())).
            sorted().
            collect(Collectors.toList());
    }

    /**
     * Returns the descriptions of the packages an application imports, ordered by package URI.
     * Packages whose description cannot be resolved are skipped rather than failing the caller: a broken
     * package server must not take the application down with it.
     *
     * @param app application resource
     * @return list of package resources
     */
    public List<com.atomgraph.linkeddatahub.apps.model.Package> getPackages(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return app.getImportedPackages().stream().
            filter(Resource::isURIResource).
            map(Resource::getURI).
            sorted().
            map(this::getPackage).
            filter(Objects::nonNull).
            collect(Collectors.toList());
    }

    /**
     * Returns the stylesheet URLs of the packages an application imports. Packages without a stylesheet
     * (ontology-only ones) are skipped.
     *
     * @param app application resource
     * @return list of stylesheet URLs
     */
    public List<URI> getStylesheets(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return getStylesheets(getPackages(app));
    }

    /**
     * Returns the stylesheet URLs of already-resolved packages, for a caller that holds the descriptions
     * and must not pay for resolving them twice.
     *
     * @param packages package resources
     * @return list of stylesheet URLs
     */
    public List<URI> getStylesheets(List<com.atomgraph.linkeddatahub.apps.model.Package> packages)
    {
        return packages.stream().
            map(com.atomgraph.linkeddatahub.apps.model.Package::getStylesheet).
            filter(Objects::nonNull).
            filter(Resource::isURIResource).
            map(stylesheet -> URI.create(stylesheet.getURI())).
            collect(Collectors.toList());
    }

    /**
     * Returns the ontology URIs of the packages an application imports. Packages without an ontology
     * (stylesheet-only ones) are skipped.
     *
     * @param app application resource
     * @return list of package ontology URIs
     */
    public List<URI> getOntologies(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return getOntologies(getPackages(app));
    }

    /**
     * Returns the ontology URIs of already-resolved packages, for a caller that holds the descriptions
     * and must not pay for resolving them twice.
     *
     * @param packages package resources
     * @return list of package ontology URIs
     */
    public List<URI> getOntologies(List<com.atomgraph.linkeddatahub.apps.model.Package> packages)
    {
        return packages.stream().
            map(com.atomgraph.linkeddatahub.apps.model.Package::getOntology).
            filter(Objects::nonNull).
            filter(Resource::isURIResource).
            map(ontology -> URI.create(ontology.getURI())).
            collect(Collectors.toList());
    }

    /**
     * Materializes the ontology of every package an application imports as a document in its admin
     * application, so that constructors delivered by a package can be edited like any other.
     *
     * The package ontology is stored verbatim, under a <code>dh:Item</code> document that names it as its
     * <code>foaf:primaryTopic</code>. The document is the document and the ontology is the ontology, which
     * is how every other ontology document on this instance is shaped - the namespace ontology included -
     * and it means the copy says exactly what the package says, with nothing rewritten.
     *
     * The ontology therefore keeps its own URI, and resolving that URI is what picks the copy up: an
     * application's repository does not map the bundled package copies, so it asks the admin store, and
     * the store answers with this graph because the graph declares the ontology. Nothing has to substitute
     * one URI for another.
     *
     * Idempotent, and offline: the model is read through the global repository, which does map the bundled
     * package copies.
     *
     * @param app application resource carrying the import set
     * @param endUserApp end-user application whose admin application holds the documents
     */
    public void materialize(com.atomgraph.linkeddatahub.apps.model.Application app, EndUserApplication endUserApp)
    {
        materialize(getPackages(app), endUserApp);
    }

    /**
     * Materializes the ontologies of already-resolved packages, for a caller that holds the descriptions
     * and must not pay for resolving them twice.
     *
     * @param packages package resources
     * @param endUserApp end-user application whose admin application holds the documents
     */
    public void materialize(List<com.atomgraph.linkeddatahub.apps.model.Package> packages, EndUserApplication endUserApp)
    {
        for (com.atomgraph.linkeddatahub.apps.model.Package pkg : packages)
        {
            if (pkg.getOntology() == null || !pkg.getOntology().isURIResource()) continue;

            URI docURI = getDocumentURI(endUserApp, pkg);
            if (docURI == null) continue;

            try
            {
                if (containsGraph(endUserApp, docURI)) continue; // already materialized

                String ontologyURI = pkg.getOntology().getURI();
                Graph graph = getSystem().getRepository().get(ontologyURI);
                if (graph == null || graph.isEmpty())
                {
                    if (log.isWarnEnabled()) log.warn("Package ontology <{}> did not resolve; not materializing", ontologyURI);
                    continue;
                }

                // the ontology goes in as it is; only the document describing it is added
                Model model = ModelFactory.createDefaultModel().add(ModelFactory.createModelForGraph(graph));

                Resource doc = model.createResource(docURI.toString()).
                    addProperty(RDF.type, DH.Item).
                    addProperty(SIOC.HAS_CONTAINER, model.createResource(endUserApp.getAdminApplication().getBaseURI().resolve(ONTOLOGIES_PATH).toString())).
                    addProperty(FOAF.primaryTopic, model.getResource(ontologyURI));
                if (pkg.hasProperty(DCTerms.title)) doc.addProperty(DCTerms.title, pkg.getProperty(DCTerms.title).getObject());

                getSystem().getServiceContext(endUserApp.getAdminApplication().getService()).getGraphStoreClient().putModel(docURI.toString(), model);

                if (log.isInfoEnabled()) log.info("Materialized package ontology <{}> as <{}>", ontologyURI, docURI);
            }
            catch (RuntimeException ex)
            {
                // a package whose ontology was never materialized is not resolvable for the application at
                // all, so OntologyFilter logs it and leaves it out of the closure rather than composing a
                // read-only copy of it that an agent would find uneditable
                if (log.isErrorEnabled()) log.error("Could not materialize package ontology as <{}>", docURI, ex);
            }
        }
    }

    /**
     * Returns the URI of the document that holds an application's copy of a package's ontology.
     * Derived from the package URI's path so the document is recognizable in the ontologies container,
     * with a UUID fallback for a package URI that has no usable path.
     *
     * @param endUserApp end-user application resource
     * @param pkg package resource
     * @return document URI, or null if the admin application is unknown
     */
    public URI getDocumentURI(EndUserApplication endUserApp, com.atomgraph.linkeddatahub.apps.model.Package pkg)
    {
        AdminApplication adminApp = endUserApp.getAdminApplication();
        if (adminApp == null) return null;

        String path = URI.create(pkg.getURI()).getPath();
        String slug = path == null ? "" : path.replaceAll("^/+|/+$", "").replace('/', '-');
        if (slug.isEmpty()) slug = UUID.nameUUIDFromBytes(pkg.getURI().getBytes(StandardCharsets.UTF_8)).toString();

        return adminApp.getUriBuilder().path(ONTOLOGIES_PATH).path("{slug}/").build(slug);
    }

    /**
     * Loads a package description from its URI.
     * Mapped locations (e.g. bundled package descriptions) and cached graphs are read from the graph
     * repository; a description that is a document of one of this instance's applications is read from that
     * application's store; other URIs are dereferenced over HTTP.
     *
     * @param packageURI package URI
     * @return package resource, or null if the description could not be resolved
     */
    public com.atomgraph.linkeddatahub.apps.model.Package getPackage(String packageURI)
    {
        final PrefixGraphRepository repository = getSystem().getRepository();
        final Model model;

        if (repository.isCached(packageURI) || repository.isMapped(packageURI))
            model = ModelFactory.createModelForGraph(repository.get(packageURI));
        else
        {
            try
            {
                // a package described by a document on THIS instance is a named graph in the instance's own
                // store, and is read there. Fetched over HTTP instead, the request would come back through
                // this application: its ontology filter, finding the ontology just evicted by the settings
                // update that declared the import, resolves the package descriptions in turn and issues the
                // same fetch - the requests nest until the proxy times out, the loop the filter already
                // guards against for uploaded ontologies
                URI docURI = UriBuilder.fromUri(packageURI).fragment(null).build(); // skip fragment from the package URI to get its graph URI
                Resource appResource = getSystem().matchApp(docURI);
                if (appResource != null && appResource.canAs(com.atomgraph.linkeddatahub.apps.model.Application.class))
                {
                    com.atomgraph.linkeddatahub.apps.model.Application app = appResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
                    model = getSystem().getServiceContext(app.getService()).getGraphStoreClient().getModel(docURI.toString());
                }
                else
                {
                    // validate package URI to prevent SSRF attacks
                    getSystem().getURLValidator().validate(URI.create(packageURI));

                    model = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes()).getModel(packageURI);
                }
            }
            catch (RuntimeException ex) // invalid URI, 404 from the package server, connection refused, timeout...
            {
                if (log.isErrorEnabled()) log.error("Loading package description failed: {}", packageURI, ex);
                return null;
            }
        }

        try
        {
            return model.getResource(packageURI).as(com.atomgraph.linkeddatahub.apps.model.Package.class);
        }
        catch (UnsupportedPolymorphismException ex)
        {
            if (log.isErrorEnabled()) log.error("Resource <{}> cannot be converted to a Package", packageURI, ex);
            return null;
        }
    }

    /**
     * Returns true if the application's admin store holds a graph with the given URI.
     *
     * @param endUserApp end-user application resource
     * @param graphURI graph URI
     * @return true if the graph exists
     */
    protected boolean containsGraph(EndUserApplication endUserApp, URI graphURI)
    {
        try
        {
            return getSystem().getServiceContext(endUserApp.getAdminApplication().getService()).getGraphStoreClient().containsModel(graphURI.toString());
        }
        catch (RuntimeException ex)
        {
            if (log.isWarnEnabled()) log.warn("Could not check for graph <{}>", graphURI, ex);
            return false;
        }
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

}
