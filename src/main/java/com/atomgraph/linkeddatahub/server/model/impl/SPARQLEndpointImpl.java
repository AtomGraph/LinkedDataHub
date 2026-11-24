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
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Authorizer;
import com.atomgraph.linkeddatahub.server.util.Grants;
import com.atomgraph.linkeddatahub.server.util.ReadableGraphsTransform;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
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
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;

/**
 * LinkedDataHub SPARQL endpoint implementation.
 * We need to subclass the Core class because we're injecting an optional <code>Service</code>.
 * A query is answered as if the store held only the documents the agent may read: {@link com.atomgraph.linkeddatahub.server.filter.request.AuthorizationFilter} decides
 * only whether the agent may use the endpoint, so the query itself is rewritten to check each graph it reads
 * ({@link ReadableGraphsTransform}).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPARQLEndpointImpl extends com.atomgraph.core.model.impl.SPARQLEndpointImpl
{

    private final Service service;
    private final Dataspace dataspace;
    private final Optional<AgentContext> agentContext;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs endpoint.
     *
     * @param request current request
     * @param httpHeaders request headers
     * @param uriInfo current request URI information
     * @param service SPARQL service
     * @param mediaTypes registry of readable/writable media types
     * @param dataspace current dataspace
     * @param agentContext the authenticated agent, if any
     * @param system system application
     */
    @Inject
    public SPARQLEndpointImpl(@Context Request request, @Context HttpHeaders httpHeaders, @Context UriInfo uriInfo, Optional<Service> service, MediaTypes mediaTypes,
            Dataspace dataspace, Optional<AgentContext> agentContext, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, httpHeaders, uriInfo, system.getServiceContext(service.get()).getQueryEndpointAccessor(system.getMaxQueryResponseLength()), mediaTypes);
        this.service = service.get();
        this.dataspace = dataspace;
        this.agentContext = agentContext;
        this.system = system;
    }

    /**
     * Answers the query over the documents the agent may read.
     * The dataset description is decided first. The protocol's <code>default-graph-uri</code> and
     * <code>named-graph-uri</code> replace the query's <code>FROM</code> and <code>FROM NAMED</code>, as the protocol
     * specifies, so both are sent as protocol parameters and the query keeps neither. A default graph is kept only
     * from the listed graphs the agent may read, since the patterns over it are not checked graph by graph; named
     * graphs are checked where <code>GRAPH</code> reads them. Then the pattern is rewritten. A query that cannot be
     * rewritten is refused with <code>400 Bad Request</code> and never sent as it was.
     *
     * @param query SPARQL query
     * @param defaultGraphUris default graph URIs
     * @param namedGraphUris named graph URIs
     * @return response builder
     */
    @Override
    public Response.ResponseBuilder getResponseBuilder(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        if (query == null) throw new BadRequestException("Query string not provided");

        boolean protocolDataset = !defaultGraphUris.isEmpty() || !namedGraphUris.isEmpty();
        List<URI> defaultGraphs = protocolDataset ? defaultGraphUris : query.getGraphURIs().stream().map(URI::create).toList();
        List<URI> namedGraphs = protocolDataset ? namedGraphUris : query.getNamedGraphURIs().stream().map(URI::create).toList();

        Authorizer authorizer = new Authorizer(getSystem(), getDataspace());
        Grants grants = authorizer.getGrants(getAgentContext().map(AgentContext::getAgent).orElse(null), ACL.Read);
        List<URI> readableDefaultGraphs = authorizer.readable(defaultGraphs, grants);

        Query datasetless = query.cloneQuery();
        datasetless.getGraphURIs().clear();
        datasetless.getNamedGraphURIs().clear();

        final Query rewritten;
        try
        {
            rewritten = ReadableGraphsTransform.rewrite(datasetless, grants, !readableDefaultGraphs.isEmpty(),
                getService().getPropertyFeatures().stream().map(Resource::asNode).collect(Collectors.toSet()));
        }
        catch (IllegalArgumentException ex)
        {
            throw new BadRequestException(ex.getMessage(), ex);
        }

        return super.getResponseBuilder(rewritten, readableDefaultGraphs, namedGraphs);
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
     * Describes the endpoint as Core does, plus the property functions the dataspace's service declares with
     * <code>sd:propertyFeature</code> (a text index's <code>text:query</code>), which the page reads to decide how to search.
     *
     * @return service description model
     */
    @Override
    public Model getServiceDescription()
    {
        Model model = super.getServiceDescription();

        model.listSubjectsWithProperty(RDF.type, SD.Service).
            forEachRemaining(endpoint -> getService().getPropertyFeatures().
                forEach(feature -> endpoint.addProperty(com.atomgraph.linkeddatahub.vocabulary.SD.propertyFeature, feature)));

        return model;
    }

    /**
     * Returns the SPARQL service this endpoint proxies.
     *
     * @return service resource
     */
    public Service getService()
    {
        return service;
    }

    /**
     * Returns the dataspace this endpoint belongs to.
     *
     * @return dataspace
     */
    public Dataspace getDataspace()
    {
        return dataspace;
    }

    /**
     * Returns the authenticated agent, if any.
     *
     * @return optional agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
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
