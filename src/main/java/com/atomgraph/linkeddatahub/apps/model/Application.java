/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.model.Service;
import java.net.URI;
import org.apache.jena.rdf.model.Resource;

/**
 * An application with a base URI, RDF ontology, SPARQL backend, and XSLT frontend.
 * This is a "logical" LinkedDataHub application which should be confused with the JAX-RS application implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Application extends Resource, com.atomgraph.core.model.Application
{
    
    /**
     * The relative path of the content-addressed file container.
     */
    public static final String UPLOADS_PATH = "uploads";

    /**
     * Returns the application's namespace ontology.
     * 
     * @return ontology resource
     */
    Resource getOntology();

    /**
     * Returns the agent who created this application.
     * 
     * @return agent resource
     */
    Resource getMaker();
    
    /**
     * Returns the application's base resource.
     * 
     * @return base resource
     */
    Resource getBase();
    
    /**
     * Returns the application's base URI.
     *
     * @return URI of the base resource
     */
    URI getBaseURI();

    /**
     * Returns the application's origin resource.
     *
     * @return origin resource
     */
    Resource getOrigin();

    /**
     * Returns the application's origin URI.
     *
     * @return URI of the origin resource
     */
    URI getOriginURI();

    /**
     * Returns applications service.
     *
     * @return service resource
     */
    @Override
    Service getService();

    /**
     * Returns applications XSLT stylesheet.
     * 
     * @return stylesheet resource
     */
    Resource getStylesheet();
    
    /**
     * Returns true if read methods are allowed without authorization.
     * 
     * @return true if read-only
     */
    boolean isReadAllowed();
    
    /**
     * Returns frontend proxy's cache URI resource.
     * 
     * @return RDF resource
     */
    Resource getFrontendProxy();
    
}
