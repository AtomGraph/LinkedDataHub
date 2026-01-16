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
package com.atomgraph.linkeddatahub.apps.model.impl;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.Package;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.server.vocabulary.LDT;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.rdf.model.impl.ResourceImpl;

import java.net.URI;
import java.util.HashSet;
import java.util.Set;


/**
 * LinkedDataHub package implementation.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class PackageImpl extends ResourceImpl implements Package
{

    /**
     * Constructs instance from node and graph.
     *
     * @param n node
     * @param g graph
     */
    public PackageImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

    @Override
    public Resource getOntology()
    {
        return getPropertyResourceValue(LDT.ontology);
    }

    @Override
    public Resource getStylesheet()
    {
        return getPropertyResourceValue(AC.stylesheet);
    }

    @Override
    public Set<Resource> getImportedPackages()
    {
        Set<Resource> packages = new HashSet<>();
        StmtIterator it = listProperties(LDH.importPackage);

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

    @Override
    public String getStylesheetPath()
    {
        String uri = getURI();
        if (uri == null)
            throw new IllegalArgumentException("Package URI cannot be null");

        try
        {
            URI uriObj = URI.create(uri);
            String host = uriObj.getHost();
            String path = uriObj.getPath();

            if (host == null)
                throw new IllegalArgumentException("Package URI must have a host: " + uri);

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
            throw new IllegalArgumentException("Invalid package URI: " + uri, e);
        }
    }

}
