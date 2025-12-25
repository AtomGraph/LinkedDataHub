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
import com.atomgraph.linkeddatahub.server.util.UriPath;
import com.atomgraph.linkeddatahub.server.util.XsltMasterUpdater;
import jakarta.inject.Inject;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.update.UpdateExecutionFactory;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
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
 * JAX-RS resource that uninstalls a LinkedDataHub package.
 * Package uninstallation involves:
 * 1. Removing package ontology triples from namespace graph
 * 2. Deleting package stylesheet from /static/packages/
 * 3. Regenerating application master stylesheet
 * 4. Removing ldh:import triple from application
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Uninstall
{
    private static final Logger log = LoggerFactory.getLogger(Uninstall.class);

    private final com.atomgraph.linkeddatahub.apps.model.Application application;

    @Context ServletContext servletContext;

    /**
     * Constructs endpoint.
     *
     * @param application matched application (admin app)
     */
    @Inject
    public Uninstall(com.atomgraph.linkeddatahub.apps.model.Application application)
    {
        this.application = application;
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
        if (packageURI == null) throw new BadRequestException("Package URI not specified");

        try
        {
            EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();

            if (log.isInfoEnabled()) log.info("Uninstalling package: {}", packageURI);

            String packagePath = UriPath.convert(packageURI);

            // 1. Remove ontology triples from namespace graph
            uninstallOntology(endUserApp, packagePath);

            // 2. Delete stylesheet from /static/<package-path>/
            uninstallStylesheet(packagePath);

            // 3. Regenerate master stylesheet
            regenerateMasterStylesheet(endUserApp, packagePath);

            // 4. Remove ldh:import triple from application
            removeImportFromApplication(endUserApp, packageURI);

            if (log.isInfoEnabled()) log.info("Successfully uninstalled package: {}", packageURI);

            // Redirect back to referer or application base
            URI redirectURI = (referer != null) ? referer : endUserApp.getBaseURI();
            return Response.seeOther(redirectURI).build();
        }
        catch (Exception e)
        {
            log.error("Failed to uninstall package: {}", packageURI, e);
            throw new jakarta.ws.rs.InternalServerErrorException("Package uninstallation failed: " + e.getMessage(), e);
        }
    }

    /**
     * Uninstalls ontology by removing triples from namespace graph.
     * This is a simplified version - a real implementation would track which triples belong to which package.
     */
    private void uninstallOntology(EndUserApplication app, String packagePath) throws IOException
    {
        if (log.isWarnEnabled())
        {
            log.warn("TODO: Remove package ontology triples from namespace graph");
            log.warn("  This requires tracking which triples belong to package: {}", packagePath);
        }
        // For now, we don't remove ontology triples as it's complex to track ownership
        // A future enhancement could use named graphs per package
    }

    /**
     * Deletes stylesheet from /static/<package-path>/
     */
    private void uninstallStylesheet(String packagePath) throws IOException
    {
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
        XsltMasterUpdater updater = new XsltMasterUpdater(getServletContext());
        updater.regenerateMasterStylesheet(packagePaths);
    }

    /**
     * Removes ldh:import triple from the end-user application resource.
     */
    private void removeImportFromApplication(EndUserApplication app, String packageURI)
    {
        // This would need to modify system.trig via SPARQL UPDATE
        // For now, log a warning that this needs manual configuration
        if (log.isWarnEnabled())
        {
            log.warn("TODO: Remove ldh:import triple from application. Manual edit required:");
            log.warn("  DELETE DATA {{ <{}> ldh:import <{}> }}", app.getURI(), packageURI);
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
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

}
