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
package com.atomgraph.linkeddatahub.model;

import org.apache.jena.rdf.model.Resource;

/**
 * Remote SPARQL service.
 * Describes the data endpoints of a SPARQL service (what it is), without any infrastructure
 * (clients, proxies) concerns (how to route to it).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Service extends Resource
{

    /**
     * Returns the SPARQL 1.1 Protocol endpoint resource.
     *
     * @return RDF resource
     */
    Resource getSPARQLEndpoint();

    /**
     * Returns the Graph Store Protocol endpoint resource.
     *
     * @return RDF resource
     */
    Resource getGraphStore();

    /**
     * Returns the quad store endpoint resource.
     *
     * @return RDF resource, or null if not configured
     */
    Resource getQuadStore();

    /**
     * Returns the HTTP Basic authentication username, if configured.
     *
     * @return username string, or null
     */
    String getAuthUser();

    /**
     * Returns the HTTP Basic authentication password, if configured.
     *
     * @return password string, or null
     */
    String getAuthPwd();

}
