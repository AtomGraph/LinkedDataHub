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

import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.resource.admin.ClearOntology;
import com.atomgraph.linkeddatahub.server.filter.response.CacheInvalidationFilter;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.UriPath;
import com.atomgraph.linkeddatahub.server.util.XSLTMasterUpdater;
import jakarta.inject.Inject;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.container.ResourceContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.commons.codec.binary.Hex;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.FileManager;
import org.glassfish.jersey.uri.UriComponent;
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

/**
 * JAX-RS resource that uninstalls a LinkedDataHub package.
 * Package uninstallation involves:
 * 1. DELETEing package ontology document from ontologies/{hash}/
 * 2. Removing owl:imports triple from namespace graph
 * 3. Clearing and reloading namespace ontology from cache
 * 4. Deleting package stylesheet from /static/{package-path}/
 * 5. Regenerating application master stylesheet
 * 6. Removing ldh:import triple from application (TODO)
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class UninstallPackage
{
    private static final Logger log = LoggerFactory.getLogger(UninstallPackage.class);

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
    public UninstallPackage(com.atomgraph.linkeddatahub.apps.model.Application application,
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
     * Uninstalls a package from the current dataspace.
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

        try
        {
            EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();

            if (log.isInfoEnabled()) log.info("Uninstalling package: {}", packageURI);

            String packagePath = UriPath.convert(packageURI);

            // 1. Remove package ontology and owl:imports from namespace graph
            uninstallOntology(endUserApp, packageURI);

            // 2. Delete stylesheet from /static/<package-path>/
            uninstallStylesheet(packagePath);

            // 3. Regenerate master stylesheet
            regenerateMasterStylesheet(endUserApp, packagePath);

            // 4. Remove ldh:import triple from application
            //removeImportFromApplication(endUserApp, packageURI);

            if (log.isInfoEnabled()) log.info("Successfully uninstalled package: {}", packageURI);

            // Redirect back to referer or application base
            URI redirectURI = (referer != null) ? referer : endUserApp.getBaseURI();
            return Response.seeOther(redirectURI).build();
        }
        catch (IOException e)
        {
            if (log.isErrorEnabled()) log.error("Failed to uninstall package: {}", packageURI, e);
            throw new WebApplicationException("Package uninstallation failed", e);
        }
    }

    /**
     * Uninstalls ontology by deleting the package ontology document and removing owl:imports from namespace graph.
     *
     * @param app the end-user application
     * @param packageURI the package URI
     * @throws IOException if uninstallation fails
     */
    private void uninstallOntology(EndUserApplication app, String packageURI) throws IOException
    {
        AdminApplication adminApp = app.getAdminApplication();

        // 1. Fetch package to get ontology URI
        com.atomgraph.linkeddatahub.apps.model.Package pkg = getPackage(packageURI);
        if (pkg == null)
        {
            if (log.isWarnEnabled()) log.warn("Package not found, skipping ontology uninstallation: {}", packageURI);
            return;
        }

        Resource ontology = pkg.getOntology();
        if (ontology == null)
        {
            if (log.isWarnEnabled()) log.warn("Package ontology not specified, skipping ontology uninstallation");
            return;
        }

        String packageOntologyURI = ontology.getURI();

        // 2. Calculate hash of package ontology URI
        String hash;
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            md.update(packageOntologyURI.getBytes(StandardCharsets.UTF_8));
            hash = Hex.encodeHexString(md.digest());
            if (log.isDebugEnabled()) log.debug("Package ontology URI '{}' hashed to '{}'", packageOntologyURI, hash);
        }
        catch (NoSuchAlgorithmException e)
        {
            if (log.isErrorEnabled()) log.error("Failed to hash package ontology URI: {}", packageOntologyURI, e);
            throw new IOException("Failed to hash package ontology URI", e);
        }

        // 3. DELETE package ontology document at ontologies/{hash}/
        URI ontologyDocumentURI = UriBuilder.fromUri(adminApp.getBaseURI()).path("ontologies/{hash}/").build(hash);
        if (log.isDebugEnabled()) log.debug("DELETEing package ontology document: {}", ontologyDocumentURI);

        GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes());

        // Delegate agent credentials if authenticated
        if (getAgentContext().isPresent())
        {
            if (log.isDebugEnabled()) log.debug("Delegating agent credentials for DELETE request");
            gsc = gsc.delegation(adminApp.getBaseURI(), getAgentContext().get());
        }

        try (Response deleteResponse = gsc.delete(ontologyDocumentURI))
        {
            if (!deleteResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to DELETE package ontology document {}: {}", ontologyDocumentURI, deleteResponse.getStatus());
                throw new IOException("Failed to DELETE package ontology document " + ontologyDocumentURI + ": " + deleteResponse.getStatus());
            }
            if (log.isDebugEnabled()) log.debug("Package ontology DELETE response status: {}", deleteResponse.getStatus());
        }

        // 4. Remove owl:imports triple from namespace ontology in namespace graph
        String namespaceOntologyURI = app.getOntology().getURI();
        URI namespaceGraphURI = UriBuilder.fromUri(adminApp.getBaseURI()).path("ontologies/namespace/").build();

        if (log.isDebugEnabled()) log.debug("Removing owl:imports from namespace ontology '{}' to package ontology '{}'", namespaceOntologyURI, packageOntologyURI);

        String updateString = String.format(
            "PREFIX owl: <http://www.w3.org/2002/07/owl#> " +
            "DELETE WHERE { <%s> owl:imports <%s> }",
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

        // 5. Clear and reload namespace ontology from cache
        if (log.isDebugEnabled()) log.debug("Clearing and reloading namespace ontology '{}'", namespaceOntologyURI);
        getResourceContext().getResource(ClearOntology.class).post(namespaceOntologyURI, null);
    }

    /**
     * Deletes stylesheet from <samp>/static/<package-path>/</samp>
     */
    private void uninstallStylesheet(String packagePath) throws IOException
    {
        EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();
        Path staticDir = Paths.get(getServletContext().getRealPath("/static"));
        Path packageDir = staticDir.resolve(packagePath);

        if (Files.exists(packageDir))
        {
            // Delete layout.xsl
            Path stylesheetFile = packageDir.resolve("layout.xsl");
            if (Files.exists(stylesheetFile))
            {
                Files.delete(stylesheetFile);
                if (log.isDebugEnabled()) log.debug("Deleted package stylesheet: {}", stylesheetFile);

                // Purge stylesheet from frontend proxy cache
                String stylesheetURL = "/static/" + packagePath + "/layout.xsl";
                if (endUserApp.getFrontendProxy() != null)
                {
                    if (log.isDebugEnabled()) log.debug("Purging stylesheet from frontend proxy cache: {}", stylesheetURL);
                    ban(endUserApp.getFrontendProxy(), stylesheetURL, false);
                }
            }

            // Delete directory if empty
            if (Files.list(packageDir).count() == 0)
            {
                Files.delete(packageDir);
                if (log.isDebugEnabled()) log.debug("Deleted package directory: {}", packageDir);
            }
        }
    }

    /**
     * Regenerates master stylesheet for the application without the uninstalled package.
     */
    private void regenerateMasterStylesheet(EndUserApplication app, String removedPackagePath) throws IOException
    {
        // Get all currently installed packages
        Set<Resource> packages = app.getImportedPackages();
        List<String> packagePaths = new ArrayList<>();

        for (Resource pkg : packages)
        {
            String pkgPath = UriPath.convert(pkg.getURI());
            // Exclude the package being removed
            if (!pkgPath.equals(removedPackagePath))
            {
                packagePaths.add(pkgPath);
            }
        }

        // Regenerate master stylesheet
        XSLTMasterUpdater updater = new XSLTMasterUpdater(getServletContext());
        updater.regenerateMasterStylesheet(packagePaths);

        // Purge master stylesheet from cache
        if (app.getFrontendProxy() != null)
        {
            String masterStylesheetURL = "/static/xsl/layout.xsl";
            if (log.isDebugEnabled()) log.debug("Purging master stylesheet from frontend proxy cache: {}", masterStylesheetURL);
            ban(app.getFrontendProxy(), masterStylesheetURL, false);
        }
    }

    /**
     * Removes <samp>ldh:import</samp> triple from the end-user application resource.
     */
//    private void removeImportFromApplication(EndUserApplication app, String packageURI)
//    {
//        // This would need to modify system.trig via SPARQL UPDATE
//        // For now, log a warning that this needs manual configuration
//        if (log.isWarnEnabled())
//        {
//            log.warn("TODO: Remove ldh:import triple from application. Manual edit required:");
//            log.warn("  DELETE DATA {{ <{}> ldh:import <{}> }}", app.getURI(), packageURI);
//        }
//    }

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
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

    /**
     * Loads package metadata from its URI using GraphStoreClient.
     * Package metadata is expected to be available as Linked Data.
     *
     * @param packageURI the package URI (e.g., https://packages.linkeddatahub.com/skos/#this)
     * @return Package instance, or null if package cannot be loaded
     */
    private com.atomgraph.linkeddatahub.apps.model.Package getPackage(String packageURI)
    {
        if (log.isDebugEnabled()) log.debug("Loading package from: {}", packageURI);

        try
        {
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

            return model.getResource(packageURI).as(com.atomgraph.linkeddatahub.apps.model.Package.class);
        }
        catch (Exception e)
        {
            if (log.isWarnEnabled()) log.warn("Failed to load package: {}", packageURI, e);
            return null;
        }
    }


    public void ban(Resource proxy, String url)
    {
        ban(proxy, url, true);
    }

    /**
     * Bans URL from the backend proxy cache.
     *
     * @param proxy proxy server URL
     * @param url banned URL
     * @param urlEncode if true, the banned URL value will be URL-encoded
     */
    public void ban(Resource proxy, String url, boolean urlEncode)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");

        // Extract path from URL - Varnish req.url only contains the path, not the full URL
        URI uri = URI.create(url);
        String path = uri.getPath();
        if (uri.getQuery() != null) path += "?" + uri.getQuery();

        final String urlValue = urlEncode ? UriComponent.encode(path, UriComponent.Type.UNRESERVED) : path;

        try (Response cr = getSystem().getClient().target(proxy.getURI()).
                request().
                header(CacheInvalidationFilter.HEADER_NAME, urlValue).
                method("BAN", Response.class))
        {
            // Response automatically closed by try-with-resources
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
