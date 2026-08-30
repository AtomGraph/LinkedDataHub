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
package com.atomgraph.linkeddatahub.apps.model;

import org.apache.jena.rdf.model.Resource;

/**
 * A LinkedDataHub package containing an ontology and optional XSLT stylesheet.
 * Packages provide reusable vocabulary support with custom templates and rendering.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Package extends Resource
{

    /**
     * Returns the package's ontology resource.
     * The ontology file (ns.ttl) contains RDF vocabulary classes/properties and template blocks.
     *
     * @return ontology resource, or null if not specified
     */
    Resource getOntology();

    /**
     * Returns the package's stylesheet resource.
     * The stylesheet file (layout.xsl) contains XSLT templates for custom rendering.
     *
     * @return stylesheet resource, or null if not specified
     */
    Resource getStylesheet();

    /**
     * Returns the packages imported by this package.
     * Packages can transitively import other packages via ldh:import property.
     *
     * @return set of imported package resources
     */
    java.util.Set<Resource> getImportedPackages();

}
