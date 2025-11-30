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

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.server.util.UriPath;
import com.atomgraph.linkeddatahub.server.util.XsltMasterUpdater;
import jakarta.inject.Inject;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * JAX-RS resource that installs a LinkedDataHub package.
 * Package installation involves:
 * 1. Fetching package metadata
 * 2. Downloading package ontology (ns.ttl) and posting to namespace graph
 * 3. Downloading package stylesheet (layout.xsl) and saving to /static/packages/
 * 4. Regenerating application master stylesheet
 * 5. Adding ldh:import triple to application
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Install
{
    private static final Logger log = LoggerFactory.getLogger(Install.class);

    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final com.atomgraph.linkeddatahub.Application system;

    @Context ServletContext servletContext;

    /**
     * Constructs endpoint.
     *
     * @param application matched application (admin app)
     * @param system system application
     */
    @Inject
    public Install(com.atomgraph.linkeddatahub.apps.model.Application application,
                   com.atomgraph.linkeddatahub.Application system)
    {
        this.application = application;
        this.system = system;
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
        if (packageURI == null) throw new BadRequestException("Package URI not specified");

        try
        {
            EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();

            if (log.isInfoEnabled()) log.info("Installing package: {}", packageURI);

            // 1. Fetch package
            com.atomgraph.linkeddatahub.apps.model.Package pkg = getPackage(packageURI);
            if (pkg == null) throw new BadRequestException("Package not found: " + packageURI);

            Resource ontology = pkg.getOntology();
            Resource stylesheet = pkg.getStylesheet();

            if (ontology == null) throw new BadRequestException("Package ontology not found");

            URI ontologyURI = URI.create(ontology.getURI());
            URI stylesheetURI = (stylesheet != null) ? URI.create(stylesheet.getURI()) : null;

            String packagePath = UriPath.convert(packageURI);

            // 2. Download and install ontology
            if (log.isDebugEnabled()) log.debug("Downloading package ontology from: {}", ontologyURI);
            Model ontologyModel = downloadOntology(ontologyURI);
            installOntology(endUserApp, ontologyModel);

            // 3. Download and install stylesheet if present
            if (stylesheetURI != null)
            {
                if (log.isDebugEnabled()) log.debug("Downloading package stylesheet from: {}", stylesheetURI);
                String stylesheetContent = downloadStylesheet(stylesheetURI);
                installStylesheet(packagePath, stylesheetContent);
            }

            // 4. Regenerate master stylesheet
            regenerateMasterStylesheet(endUserApp, packagePath);

            // 5. Add ldh:import triple to application (in system.trig)
            addImportToApplication(endUserApp, packageURI);

            if (log.isInfoEnabled()) log.info("Successfully installed package: {}", packageURI);

            // Redirect back to referer or application base
            URI redirectURI = (referer != null) ? referer : endUserApp.getBaseURI();
            return Response.seeOther(redirectURI).build();
        }
        catch (BadRequestException | IOException e)
        {
            log.error("Failed to install package: {}", packageURI, e);
            throw new InternalServerErrorException("Package installation failed: " + e.getMessage(), e);
        }
    }

    /**
     * Loads package metadata from its URI using LinkedDataClient.
     * Package metadata is expected to be available as Linked Data.
     *
     * @param packageURI the package URI (e.g., https://packages.linkeddatahub.com/skos/#this)
     * @return Package instance
     * @throws NotFoundException if package cannot be found (404)
     * @throws InternalServerErrorException if package cannot be loaded for other reasons
     */
    private com.atomgraph.linkeddatahub.apps.model.Package getPackage(String packageURI)
    {
        try
        {
            if (log.isDebugEnabled()) log.debug("Loading package from: {}", packageURI);

            LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes());
            Model model = ldc.getModel(packageURI);

            return model.getResource(packageURI).as(com.atomgraph.linkeddatahub.apps.model.Package.class);
        }
        catch (WebApplicationException e)
        {
            // Re-throw HTTP client errors from LinkedDataClient as-is (404, 403, etc.)
            log.error("HTTP error loading package from: {}", packageURI, e);
            throw e;
        }
        catch (Exception e)
        {
            log.error("Failed to load package from: {}", packageURI, e);
            throw new InternalServerErrorException("Failed to load package from: " + packageURI, e);
        }
    }

    /**
     * Downloads RDF from a URI using LinkedDataClient.
     */
    private Model downloadOntology(URI uri) throws IOException
    {
        if (log.isDebugEnabled()) log.debug("Downloading RDF from: {}", uri);

        LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes());
        return ldc.getModel(uri.toString());
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
        try (Response response = target.request("text/xsl", "text/*;q=0.8").get())
        {
            if (!response.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                throw new IOException("Failed to download XSLT from " + uri + ": " + response.getStatus());
            }

            return response.readEntity(String.class);
        }
    }

    /**
     * Installs ontology by POSTing to namespace graph.
     */
    private void installOntology(EndUserApplication app, Model ontologyModel) throws IOException
    {
        if (log.isDebugEnabled()) log.debug("Posting package ontology to namespace graph");

        // POST to admin namespace graph
        AdminApplication adminApp = app.getAdminApplication();
        String namespaceGraphURI = UriBuilder.fromUri(adminApp.getBaseURI()).path("model/ontologies/namespace").build().toString();

        // Use Graph Store Protocol to add ontology to namespace graph
        adminApp.getService().getGraphStoreClient().add(namespaceGraphURI, ontologyModel);
    }

    /**
     * Installs stylesheet to /static/<package-path>/layout.xsl
     */
    private void installStylesheet(String packagePath, String stylesheetContent) throws IOException
    {
        Path staticDir = Paths.get(getServletContext().getRealPath("/static"));
        Path packageDir = staticDir.resolve(packagePath);
        Files.createDirectories(packageDir);

        Path stylesheetFile = packageDir.resolve("layout.xsl");
        Files.writeString(stylesheetFile, stylesheetContent);

        if (log.isDebugEnabled()) log.debug("Installed package stylesheet at: {}", stylesheetFile);
    }

    /**
     * Regenerates master stylesheet for the application.
     */
    private void regenerateMasterStylesheet(EndUserApplication app, String newPackagePath) throws IOException
    {
        // Get all currently installed packages
        Set<Resource> packages = app.getImportedPackages();
        List<String> packagePaths = new ArrayList<>();

        for (Resource pkg : packages)
            packagePaths.add(UriPath.convert(pkg.getURI()));

        // Add the new package
        if (!packagePaths.contains(newPackagePath))
            packagePaths.add(newPackagePath);

        // Regenerate master stylesheet
        String hostname = app.getBaseURI().getHost();
        XsltMasterUpdater updater = new XsltMasterUpdater(getServletContext());
        updater.regenerateMasterStylesheet(hostname, packagePaths);
    }

    /**
     * Adds ldh:import triple to the end-user application resource.
     */
    private void addImportToApplication(EndUserApplication app, String packageURI)
    {
        // This would need to modify system.trig via SPARQL UPDATE
        // For now, log a warning that this needs manual configuration
        if (log.isWarnEnabled())
        {
            log.warn("TODO: Add ldh:import triple to application. Manual edit required:");
            log.warn("  <{}> ldh:import <{}> .", app.getURI(), packageURI);
        }
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

}
