/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
 * A dataspace that returns Linked Data.
 * Can either have a base or a prefix URI. Does not have a service unlike applications.
 * Used for proxying third party Linked Data services.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Dataset extends Resource
{

    /**
     * Returns the URI that is the prefix of this dataset.
     * All URIs in the dataset should be relative to the prefix URI.
     * 
     * @return prefix URI
     */
    Resource getPrefix();
    
    /**
     * Returns the proxy URI resource.
     * URI of the service that URIs in this dataset are proxied through.
     * 
     * @return proxy resource
     */
    Resource getProxy();
    
    /**
     * Returns the proxy URI.URI of the service that URIs in this dataset are proxied through.
     *
     * @return proxy URI
     */
    URI getProxyURI();
    
    /**
     * Returns URI rewritten using the proxy URI.
     * 
     * @param uri dataset resource URI
     * @return proxied URI
     */
    URI getProxied(URI uri);
    
    /**
     * Returns SPARQL service for this dataset.
     * 
     * @return service resource
     */
    Service getService();

}
