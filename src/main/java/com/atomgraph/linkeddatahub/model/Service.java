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
import com.sun.jersey.api.client.Client;
import java.net.URI;
import org.apache.jena.rdf.model.Resource;

/**
 * Remote SPARQL service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Service extends com.atomgraph.core.model.RemoteService, Resource
{

    URI getProxy();
    
    Client getClient();

    MediaTypes getMediaTypes();

    Integer getMaxGetRequestSize();

    @Override
    EndpointAccessor getEndpointAccessor();
    
}
