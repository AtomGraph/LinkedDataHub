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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.Package;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import jakarta.ws.rs.InternalServerErrorException;
import org.apache.jena.rdf.model.*;
import org.apache.jena.riot.RDFDataMgr;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.util.*;

/**
 * Package manager for LinkedDataHub packages.
 * Handles loading package metadata and content (ontologies and stylesheets).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class PackageManager
{
    private static final Logger log = LoggerFactory.getLogger(PackageManager.class);

    /**
     * Get the list of package URIs imported by an application.
     *
     * @param app the application
     * @return set of package URIs
     */
    public Set<Resource> getImportedPackages(Application app)
    {
        if (app == null) return Collections.emptySet();

        Set<Resource> packages = new HashSet<>();
        StmtIterator it = app.listProperties(LDH.importPackage);
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                if (stmt.getObject().isResource())
                    packages.add(stmt.getResource());
            }
        }
        finally
        {
            it.close();
        }

        return packages;
    }

    /**
     * Load package from its URI.
     * Package metadata is expected to be available as Linked Data.
     *
     * @param packageURI the package URI (e.g., https://packages.linkeddatahub.com/skos/#this)
     * @return Package instance
     * @throws InternalServerErrorException if package cannot be loaded
     */
    public Package getPackage(String packageURI)
    {
        try
        {
            if (log.isDebugEnabled()) log.debug("Loading package from: {}", packageURI);
            Model model = ModelFactory.createDefaultModel();
            RDFDataMgr.read(model, packageURI);

            return model.getResource(packageURI).as(Package.class);
        }
        catch (Exception e)
        {
            log.error("Failed to load package from: {}", packageURI, e);
            throw new InternalServerErrorException("Failed to load package from: " + packageURI, e);
        }
    }

    /**
     * Load a package's ontology from its ns.ttl URI.
     *
     * @param ontologyURI the URI of the package's ontology file
     * @return RDF model containing the ontology
     * @throws IllegalArgumentException if ontologyURI is null
     * @throws InternalServerErrorException if ontology cannot be loaded
     */
    public Model loadPackageOntology(URI ontologyURI)
    {
        if (ontologyURI == null)
            throw new IllegalArgumentException("Package ontology URI cannot be null");

        String uriString = ontologyURI.toString();

        try
        {
            if (log.isDebugEnabled()) log.debug("Loading package ontology from: {}", uriString);
            Model model = ModelFactory.createDefaultModel();
            RDFDataMgr.read(model, uriString);
            return model;
        }
        catch (Exception e)
        {
            log.error("Failed to load package ontology from: {}", uriString, e);
            throw new InternalServerErrorException("Failed to load package ontology from: " + uriString, e);
        }
    }

    /**
     * Converts a package URI to a filesystem path by reversing hostname components.
     * Example: https://packages.linkeddatahub.com/skos/#this -> com/linkeddatahub/packages/skos
     *
     * @param packageURI the package URI
     * @return filesystem path relative to static directory
     * @throws IllegalArgumentException if URI is invalid
     */
    public String uriToPath(String packageURI)
    {
        if (packageURI == null)
            throw new IllegalArgumentException("Package URI cannot be null");

        try
        {
            URI uri = URI.create(packageURI);
            String host = uri.getHost();
            String path = uri.getPath();

            if (host == null)
                throw new IllegalArgumentException("Package URI must have a host: " + packageURI);

            // Reverse hostname components: packages.linkeddatahub.com -> com/linkeddatahub/packages
            String[] hostParts = host.split("\\.");
            StringBuilder reversedHost = new StringBuilder();
            for (int i = hostParts.length - 1; i >= 0; i--)
            {
                reversedHost.append(hostParts[i]);
                if (i > 0) reversedHost.append("/");
            }

            // Append path without leading/trailing slashes and fragment
            if (path != null && !path.isEmpty() && !path.equals("/"))
            {
                String cleanPath = path.replaceAll("^/+|/+$", ""); // Remove leading/trailing slashes
                return reversedHost + "/" + cleanPath;
            }

            return reversedHost.toString();
        }
        catch (IllegalArgumentException e)
        {
            throw new IllegalArgumentException("Invalid package URI: " + packageURI, e);
        }
    }

}
