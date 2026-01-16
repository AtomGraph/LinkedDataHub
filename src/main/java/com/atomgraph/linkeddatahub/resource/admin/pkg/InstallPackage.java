/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.admin.pkg;

import static com.atomgraph.client.MediaType.TEXT_XSL;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.resource.admin.ClearOntology;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import com.atomgraph.linkeddatahub.server.util.XSLTMasterUpdater;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import jakarta.inject.Inject;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ResourceContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.commons.codec.binary.Hex;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.FileManager;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * JAX-RS resource that installs a LinkedDataHub package.
 * Package installation involves:
 * 1. Fetching package metadata
 * 2. Downloading and validating package resources (ontology and stylesheet)
 * 3. Creating item document under packages/ container with package metadata
 * 4. PUTting package ontology as new document under ontologies/{hash}/
 * 5. Adding owl:imports of package ontology to namespace ontology
 * 6. Saving package stylesheet (layout.xsl) to /static/{package-path}/
 * 7. Regenerating application master stylesheet
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class InstallPackage
{
    private static final Logger log = LoggerFactory.getLogger(InstallPackage.class);

    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final com.atomgraph.linkeddatahub.Application system;
    private final DataManager dataManager;
    private final Optional<AgentContext> agentContext;

    @Context ServletContext servletContext;
    @Context ResourceContext resourceContext;

    /**
     * Constructs endpoint.
     *
     * @param application matched application (admin app)
     * @param system system application
     * @param dataManager data manager
     * @param agentContext authenticated agent context
     */
    @Inject
    public InstallPackage(com.atomgraph.linkeddatahub.apps.model.Application application,
                   com.atomgraph.linkeddatahub.Application system,
                   DataManager dataManager,
                   Optional<AgentContext> agentContext)
    {
        this.application = application;
        this.system = system;
        this.dataManager = dataManager;
        this.agentContext = agentContext;
    }

    /**
     * Installs a package into the current dataspace.
     *
     * @param packageURI the package URI (e.g., https://packages.linkeddatahub.com/skos/#this)
     * @param referer the referring URL
     * @return JAX-RS response
     */
    @POST
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public Response post(@FormParam("package-uri") String packageURI, @HeaderParam("Referer") URI referer)
    {
        if (packageURI == null)
        {
            if (log.isErrorEnabled()) log.error("Package URI not specified");
            throw new BadRequestException("Package URI not specified");
        }

        // Validate package URI to prevent SSRF attacks
        new URLValidator(URI.create(packageURI)).validate();

        if (log.isInfoEnabled()) log.info("Installing package: {}", packageURI);
        com.atomgraph.linkeddatahub.apps.model.Package pkg = getPackage(packageURI);
        if (pkg == null)
        {
            if (log.isErrorEnabled()) log.error("Loading package failed: {}", packageURI);
            throw new WebApplicationException("Loading package failed", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }

        Resource ontology = pkg.getOntology();
        Resource stylesheet = pkg.getStylesheet();

        if (ontology == null && stylesheet == null)
        {
            if (log.isErrorEnabled()) log.error("Package ontology and stylesheet are both unspecified for package: {}", packageURI);
            throw new WebApplicationException("Package ontology and stylesheet are both unspecified", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }

        try
        {
            EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();
            AdminApplication adminApp = endUserApp.getAdminApplication();

            if (ontology != null)
            {
                // Validate ontology URI to prevent SSRF attacks
                new URLValidator(URI.create(ontology.getURI())).validate();

                if (log.isDebugEnabled()) log.debug("Downloading package ontology from: {}", ontology.getURI());
                Model ontologyModel = downloadOntology(ontology.getURI());

                installOntology(endUserApp, ontologyModel, ontology.getURI());
            }

            if (stylesheet != null)
            {
                URI stylesheetURI = URI.create(stylesheet.getURI());
                String packagePath = pkg.getStylesheetPath();

                // Validate stylesheet URI to prevent SSRF attacks
                new URLValidator(stylesheetURI).validate();

                if (log.isDebugEnabled()) log.debug("Downloading package stylesheet from: {}", stylesheetURI);
                String stylesheetContent = downloadStylesheet(stylesheetURI);

                installStylesheet(Paths.get(getServletContext().getRealPath("/static")).resolve(packagePath).resolve("layout.xsl"), stylesheetContent);

                // Purge package stylesheet from frontend proxy cache
                String stylesheetURL = "/static/" + packagePath + "/layout.xsl";
                if (endUserApp.getFrontendProxy() != null)
                {
                    if (log.isDebugEnabled()) log.debug("Purging package stylesheet from frontend proxy cache: {}", stylesheetURL);
                    getSystem().ban(endUserApp.getFrontendProxy(), stylesheetURL, false);
                }

                regenerateMasterStylesheet(endUserApp, pkg);

                // Purge master stylesheet from frontend proxy cache
                if (endUserApp.getFrontendProxy() != null)
                {
                    if (log.isDebugEnabled()) log.debug("Purging master stylesheet from frontend proxy cache: {}", com.atomgraph.linkeddatahub.Application.MASTER_STYLESHEET_PATH);
                    getSystem().ban(endUserApp.getFrontendProxy(), com.atomgraph.linkeddatahub.Application.MASTER_STYLESHEET_PATH, false);
                }
            }

            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes());
            if (getAgentContext().isPresent()) gsc = gsc.delegation(adminApp.getBaseURI(), getAgentContext().get());

            String slug = hashURI(packageURI);
            URI packageDocumentURI = adminApp.getUriBuilder().
                path("packages/").
                path("{slug}/").
                build(slug);
            Model packageDocModel = ModelFactory.createDefaultModel();
            packageDocModel.add(pkg.getModel());
            Resource container = packageDocModel.createResource(adminApp.getBaseURI().resolve("packages/").toString());
            createPackageDocument(packageDocModel, packageDocumentURI, container, pkg, slug);
            new Skolemizer(packageDocumentURI.toString()).apply(packageDocModel);
            putPackageDocument(gsc, packageDocumentURI, packageDocModel);
            
            if (log.isInfoEnabled()) log.info("Successfully installed package: {}", packageURI);

            // Redirect back to referer or application base
            URI redirectURI = (referer != null) ? referer : endUserApp.getBaseURI();
            return Response.seeOther(redirectURI).build();
        }
        catch (IOException e)
        {
            log.error("Failed to install package: {}", packageURI, e);
            throw new WebApplicationException("Package installation failed", e);
        }
    }

    /**
     * Loads package metadata from its URI using GraphStoreClient.
     * Package metadata is expected to be available as Linked Data.
     *
     * @param gsc the graph store client
     * @param packageURI the package URI (e.g., https://packages.linkeddatahub.com/skos/#this)
     * @return Package instance
     * @throws NotFoundException if package cannot be found (404)
     */
    private com.atomgraph.linkeddatahub.apps.model.Package getPackage(String packageURI)
    {
        if (log.isDebugEnabled()) log.debug("Loading package from: {}", packageURI);

        final Model model;

        // check if we have the model in the cache first and if yes, return it from there instead making an HTTP request
        if (((FileManager)getDataManager()).hasCachedModel(packageURI) ||
                (getDataManager().isResolvingMapped() && getDataManager().isMapped(packageURI))) // read mapped URIs (such as system ontologies) from a file
        {
            if (log.isDebugEnabled()) log.debug("hasCachedModel({}): {}", packageURI, ((FileManager)getDataManager()).hasCachedModel(packageURI));
            if (log.isDebugEnabled()) log.debug("isMapped({}): {}", packageURI, getDataManager().isMapped(packageURI));
            model = getDataManager().loadModel(packageURI);
        }
        else
        {
            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes());
            model = gsc.getModel(packageURI);
        }

        try
        {
            return model.getResource(packageURI).as(com.atomgraph.linkeddatahub.apps.model.Package.class);
        }
        catch (ConversionException ex)
        {
            return null;
        }
    }

    /**
     * Downloads RDF from a URI using GraphStoreClient.
     */
    private Model downloadOntology(String uri)
    {
        if (log.isDebugEnabled()) log.debug("Downloading ontology from: {}", uri);

        // check if we have the model in the cache first and if yes, return it from there instead making an HTTP request
        if (((FileManager)getDataManager()).hasCachedModel(uri) ||
                (getDataManager().isResolvingMapped() && getDataManager().isMapped(uri))) // read mapped URIs (such as system ontologies) from a file
        {
            if (log.isDebugEnabled()) log.debug("hasCachedModel({}): {}", uri, ((FileManager)getDataManager()).hasCachedModel(uri));
            if (log.isDebugEnabled()) log.debug("isMapped({}): {}", uri, getDataManager().isMapped(uri));
            return getDataManager().loadModel(uri);
        }
        else
        {
            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes());
            return gsc.getModel(uri);
        }
    }

    /**
     * Downloads XSLT stylesheet content from a URI using Jersey Client.
     * Prioritizes text/xsl, falls back to text/*.
     */
    private String downloadStylesheet(URI uri) throws IOException
    {
        if (log.isDebugEnabled()) log.debug("Downloading XSLT stylesheet from: {}", uri);

        WebTarget target = getClient().target(uri);
        // Prioritize text/xsl (q=1.0), then any text/* (q=0.8)
        try (Response response = target.request(TEXT_XSL, "text/*;q=0.8").get())
        {
            if (!response.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to download XSLT from {}: {}", uri, response.getStatus());
                throw new IOException("Failed to download XSLT from " + uri + ": " + response.getStatus());
            }

            return response.readEntity(String.class);
        }
    }

    /**
     * Hashes a URI using SHA-1 to create a unique document slug.
     *
     * @param uri the URI to hash
     * @return the SHA-1 hash as a hexadecimal string
     * @throws IOException if hashing fails
     */
    private String hashURI(String uri) throws IOException
    {
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            md.update(uri.getBytes(StandardCharsets.UTF_8));
            String hash = Hex.encodeHexString(md.digest());
            if (log.isDebugEnabled()) log.debug("URI '{}' hashed to '{}'", uri, hash);
            return hash;
        }
        catch (NoSuchAlgorithmException e)
        {
            if (log.isErrorEnabled()) log.error("Failed to hash URI: {}", uri, e);
            throw new IOException("Failed to hash URI", e);
        }
    }

    /**
     * Installs ontology by PUTting as a new document and adding owl:imports to namespace ontology.
     *
     * @param app the end-user application
     * @param ontologyModel the package ontology model
     * @param packageOntologyURI the package ontology URI
     * @throws IOException if installation fails
     */
    private void installOntology(EndUserApplication app, Model ontologyModel, String packageOntologyURI) throws IOException
    {
        AdminApplication adminApp = app.getAdminApplication();

        // 1. Create hash of package ontology URI to use as document slug
        String hash = hashURI(packageOntologyURI);

        GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes());

        // Delegate agent credentials if authenticated
        if (getAgentContext().isPresent())
        {
            if (log.isDebugEnabled()) log.debug("Delegating agent credentials for PUT request");
            gsc = gsc.delegation(adminApp.getBaseURI(), getAgentContext().get());
        }
        
        // 2. PUT package ontology as a document under model/ontologies/{hash}/ (overwrites if exists)
        URI ontologyDocumentURI = UriBuilder.fromUri(adminApp.getBaseURI()).path("ontologies/{hash}/").build(hash);
        if (log.isDebugEnabled()) log.debug("PUTting package ontology to document: {}", ontologyDocumentURI);

        try (Response putResponse = gsc.put(ontologyDocumentURI, ontologyModel))
        {
            if (!putResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to PUT package ontology to {}: {}", ontologyDocumentURI, putResponse.getStatus());
                throw new IOException("Failed to PUT package ontology to " + ontologyDocumentURI + ": " + putResponse.getStatus());
            }
            if (log.isDebugEnabled()) log.debug("Package ontology PUT response status: {}", putResponse.getStatus());
        }

        // 3. Add owl:imports triple to namespace ontology in namespace graph
        String namespaceOntologyURI = app.getOntology().getURI();
        URI namespaceGraphURI = UriBuilder.fromUri(adminApp.getBaseURI()).path("ontologies/namespace/").build();

        if (log.isDebugEnabled()) log.debug("Adding owl:imports from namespace ontology '{}' to package ontology '{}'", namespaceOntologyURI, packageOntologyURI);

        String updateString = String.format(
            "PREFIX owl: <http://www.w3.org/2002/07/owl#> " +
            "INSERT { <%s> owl:imports <%s> } WHERE { }",
            namespaceOntologyURI, packageOntologyURI
        );
        UpdateRequest updateRequest = UpdateFactory.create(updateString);

        try (Response patchResponse = gsc.patch(namespaceGraphURI, updateRequest))
        {
            if (!patchResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to PATCH namespace graph {}: {}", namespaceGraphURI, patchResponse.getStatus());
                throw new IOException("Failed to PATCH namespace graph " + namespaceGraphURI + ": " + patchResponse.getStatus());
            }
            if (log.isDebugEnabled()) log.debug("Namespace graph PATCH response status: {}", patchResponse.getStatus());
        }

        if (log.isDebugEnabled()) log.debug("Clearing and reloading namespace ontology '{}'", namespaceOntologyURI);
        getResourceContext().getResource(ClearOntology.class).post(namespaceOntologyURI, null);
    }

    /**
     * Installs stylesheet to <samp>/static/<package-path>/layout.xsl</samp>
     */
    private void installStylesheet(Path stylesheetFile, String stylesheetContent) throws IOException
    {
        Files.createDirectories(stylesheetFile.getParent());
        Files.writeString(stylesheetFile, stylesheetContent);

        if (log.isDebugEnabled()) log.debug("Installed package stylesheet at: {}", stylesheetFile);
    }

    /**
     * Regenerates master stylesheet for the application.
     *
     * @param app the application
     * @param newPackage the package being installed
     * @throws IOException if regeneration fails
     */
    private void regenerateMasterStylesheet(EndUserApplication app, com.atomgraph.linkeddatahub.apps.model.Package newPackage) throws IOException
    {
        // Get all currently installed packages and convert to stylesheet paths
        Set<Resource> packageResources = app.getImportedPackages();
        List<String> packagePaths = new ArrayList<>();

        for (Resource pkgRes : packageResources)
        {
            com.atomgraph.linkeddatahub.apps.model.Package pkg = pkgRes.as(com.atomgraph.linkeddatahub.apps.model.Package.class);
            packagePaths.add(pkg.getStylesheetPath());
        }

        // Add the new package path
        String newPath = newPackage.getStylesheetPath();
        if (!packagePaths.contains(newPath))
            packagePaths.add(newPath);

        // Regenerate master stylesheet (XSLTMasterUpdater works with paths)
        XSLTMasterUpdater updater = new XSLTMasterUpdater(getServletContext());
        updater.regenerateMasterStylesheet(packagePaths);
    }

    /**
     * Creates a package document item.
     *
     * @param model the model to populate
     * @param packageDocumentURI the document URI
     * @param container the container resource
     * @param pkg the package resource
     * @param slug the document slug
     * @return the document item resource
     */
    private Resource createPackageDocument(Model model,
                                          URI packageDocumentURI,
                                          Resource container,
                                          com.atomgraph.linkeddatahub.apps.model.Package pkg,
                                          String slug)
    {
        return model.createResource(packageDocumentURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, slug).
            addLiteral(DCTerms.title, pkg.getProperty(DCTerms.title).getString()).
            addProperty(FOAF.primaryTopic, pkg);
    }

    /**
     * PUTs a package document to the specified URI.
     *
     * @param gsc the graph store client
     * @param packageDocumentURI the document URI
     * @param packageDocModel the package document model
     * @throws IOException if PUT fails
     */
    private void putPackageDocument(GraphStoreClient gsc, URI packageDocumentURI, Model packageDocModel) throws IOException
    {
        if (log.isDebugEnabled()) log.debug("PUTting package document to: {}", packageDocumentURI);

        try (Response putResponse = gsc.put(packageDocumentURI, packageDocModel))
        {
            if (!putResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to PUT package document to {}: {}", packageDocumentURI, putResponse.getStatus());
                throw new IOException("Failed to PUT package document to " + packageDocumentURI + ": " + putResponse.getStatus());
            }
            if (log.isDebugEnabled()) log.debug("Package document PUT response status: {}", putResponse.getStatus());
        }

        if (log.isInfoEnabled()) log.info("Successfully created package document at: {}", packageDocumentURI);
    }

    /**
     * Returns the current application.
     *
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
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

    /**
     * Returns Jersey HTTP client.
     *
     * @return HTTP client
     */
    public Client getClient()
    {
        return getSystem().getClient();
    }

    /**
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

    /**
     * Returns RDF data manager.
     *
     * @return RDF data manager
     */
    public DataManager getDataManager()
    {
        return dataManager;
    }

    /**
     * Returns JAX-RS resource context.
     *
     * @return resource context
     */
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }

    /**
     * Returns the authenticated agent context.
     *
     * @return agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }

}
