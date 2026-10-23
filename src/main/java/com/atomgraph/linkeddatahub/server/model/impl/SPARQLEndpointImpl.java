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
import java.net.URI;
import java.util.List;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.update.UpdateRequest;

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
     * @param httpHeaders request headers
     * @param uriInfo current request URI information
     * @param service SPARQL service
     * @param mediaTypes registry of readable/writable media types
     * @param system system application
     */
    @Inject
    public SPARQLEndpointImpl(@Context Request request, @Context HttpHeaders httpHeaders, @Context UriInfo uriInfo, Optional<Service> service, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(request, httpHeaders, uriInfo, system.getServiceContext(service.get()).getQueryEndpointAccessor(system.getMaxQueryResponseLength()), mediaTypes);
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
     * Handles a URL-encoded form POST.
     * A query is executed; an <code>update</code> parameter is refused with <code>405 Method Not Allowed</code>,
     * since writes go through the Graph Store Protocol, where they are authorized per document.
     * 
     * @param queryString SPARQL query string
     * @param updateString SPARQL update string
     * @param defaultGraphUris default graph URIs
     * @param namedGraphUris named graph URIs
     * @param usingGraphUris <code>USING</code> graph URIs
     * @param usingNamedGraphUris <code>USING NAMED</code> graph URIs
     * @return response
     */
    @Override
    @POST
    @Consumes(com.atomgraph.core.MediaType.APPLICATION_FORM_URLENCODED)
    public Response post(@FormParam(QUERY) String queryString, @FormParam(UPDATE) String updateString,
            @FormParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @FormParam(NAMED_GRAPH_URI) List<URI> namedGraphUris,
            @FormParam(USING_GRAPH_URI) List<URI> usingGraphUris, @FormParam(USING_NAMED_GRAPH_URI) List<URI> usingNamedGraphUris)
    {
        if (updateString != null) throw updateNotAllowed();
        
        return super.post(queryString, null, defaultGraphUris, namedGraphUris, usingGraphUris, usingNamedGraphUris);
    }
    
    /**
     * Refuses a SPARQL Update request with <code>405 Method Not Allowed</code>.
     * Writes go through the Graph Store Protocol, where they are authorized per document.
     * 
     * @param update SPARQL update
     * @param usingGraphUris <code>USING</code> graph URIs
     * @param usingNamedGraphUris <code>USING NAMED</code> graph URIs
     * @return never returns
     */
    @Override
    @POST
    @Consumes(com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE)
    public Response post(UpdateRequest update, @QueryParam(USING_GRAPH_URI) List<URI> usingGraphUris, @QueryParam(USING_NAMED_GRAPH_URI) List<URI> usingNamedGraphUris)
    {
        throw updateNotAllowed();
    }
    
    /**
     * Returns the exception that refuses SPARQL Update on this endpoint.
     * The <code>Allow</code> header lists the methods this endpoint does accept (queries only).
     * 
     * @return 405 exception
     */
    public static NotAllowedException updateNotAllowed()
    {
        // the explicit array selects the (message, allowed, moreAllowed...) constructor; with plain varargs the
        // message would be ambiguous with (allowed, moreAllowed...) and could end up in the Allow header
        return new NotAllowedException("SPARQL updates are not allowed on the <sparql> endpoint", HttpMethod.GET, new String[] { HttpMethod.POST });
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
        return new com.atomgraph.core.model.impl.Response(getRequest(), getHttpHeaders(),
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
