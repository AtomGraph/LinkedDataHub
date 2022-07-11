// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0


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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.model.EndpointAccessor;
import javax.ws.rs.client.Client;
import org.apache.jena.rdf.model.Resource;

/**
 * Remote SPARQL service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Service extends com.atomgraph.core.model.RemoteService, Resource
{

    @Override
    EndpointAccessor getEndpointAccessor();

    /**
     * Returns backend's proxy cache URI resource.
     * 
     * @return RDF resource
     */
    Resource getProxy();
    
    /**
     * Returns HTTP client.
     * 
     * @return HTTP client
     */
    Client getClient();

    /**
     * Returns a registry of readable/writable media types.
     * 
     * @return media type registry
     */
    MediaTypes getMediaTypes();

    /**
     * Returns the maximum size of SPARQL <code>GET</code> requests.
     * 
     * @return request size in bytes
     */
    Integer getMaxGetRequestSize();
    
}
