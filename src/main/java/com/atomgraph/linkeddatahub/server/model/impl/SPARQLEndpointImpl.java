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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Service;
import java.util.List;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;

/**
 * LinkedDataHub SPARQL endpoint implementation.
 * We need to subclass the Core class because we're injecting an optional <code>Service</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPARQLEndpointImpl extends com.atomgraph.core.model.impl.SPARQLEndpointImpl
{

    /**
     * Constructs endpoint.
     *
     * @param request current request
     * @param uriInfo current request URI information
     * @param service SPARQL service
     * @param mediaTypes registry of readable/writable media types
     * @param system system application
     */
    @Inject
    public SPARQLEndpointImpl(@Context Request request, @Context UriInfo uriInfo, Optional<Service> service, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(request, uriInfo, system.getServiceContext(service.get()).getEndpointAccessor(), mediaTypes);
    }
    
    /**
     * Returns the query languages this endpoint supports.
     * Only queries are advertised: writes go through the Graph Store Protocol.
     * 
     * @return list of <code>sd:Language</code> resources
     */
    @Override
    public List<Resource> getSupportedLanguages()
    {
        return List.of(SD.SPARQL11Query);
    }
    
    /**
     * Returns response builder for the given RDF model.
     * 
     * @param model RDF model
     * @return response builder
     */
    @Override
    public Response.ResponseBuilder getResponseBuilder(Model model)
    {
        return new com.atomgraph.core.model.impl.Response(getRequest(),
                model,
                null,
                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
                getWritableMediaTypes(Model.class),
                getLanguages(),
                getEncodings(),
                new HTMLMediaTypePredicate()).
            getResponseBuilder();
    }
    
}
