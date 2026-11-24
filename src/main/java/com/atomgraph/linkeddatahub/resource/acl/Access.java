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
package com.atomgraph.linkeddatahub.resource.acl;

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Authorizer;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Optional;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * ACL access control endpoint for querying authorization data.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Access
{
    
    private static final Logger log = LoggerFactory.getLogger(Access.class);

    private final Request request;
    private final HttpHeaders httpHeaders;
    private final UriInfo uriInfo;
    private final MediaTypes mediaTypes;
    private final EndUserDataspace application;
    private final Optional<AgentContext> agentContext;
    private final com.atomgraph.linkeddatahub.Application system;
    
    /**
     * Constructs endpoint from the in-memory ontology model.
     * 
     * @param request current request
     * @param httpHeaders request headers
     * @param uriInfo current request's URI info
     * @param mediaTypes supported media types
     * @param application current end-user application
     * @param agentContext agent context
     * @param system system application
     */
    @Inject
    public Access(@Context Request request, @Context HttpHeaders httpHeaders, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            Dataspace application, Optional<AgentContext> agentContext,
            com.atomgraph.linkeddatahub.Application system)
    {
        if (!application.canAs(EndUserDataspace.class)) throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");
        this.request = request;
        this.httpHeaders = httpHeaders;
        this.uriInfo = uriInfo;
        this.mediaTypes = mediaTypes;
        this.application = application.as(EndUserDataspace.class);
        this.agentContext = agentContext;
        this.system = system;
    }

    /**
     * Implements the HTTP GET method for retrieving access control information.
     *
     * @return response with access control data
     */
    @GET
    public Response get()
    {
        final Agent agent = getAgentContext().map(AgentContext::getAgent).orElse(null);
   
        try
        {
            if (!getUriInfo().getQueryParameters().containsKey(SPIN.THIS_VAR_NAME)) throw new BadRequestException("?this query param is not provided");
            
            Resource accessTo = ResourceFactory.createResource(new URI(getUriInfo().getQueryParameters().getFirst(SPIN.THIS_VAR_NAME)).toString()); // ?this query param needs to be passed
            if (log.isDebugEnabled()) log.debug("Loading current agent's authorizations for the <{}> document", accessTo);
            
            // the same decision as AuthorizationFilter's: the document's context from the end-user store, matched by the ACL query
            Authorizer authorizer = new Authorizer(getSystem(), getDataspace());
            Model authModel = authorizer.getAuthorizations(authorizer.getDocumentContext(accessTo), agent);

            // filter out authorizations with acl:accessToClass foaf:Agent - all agents already have that access
            ResIterator agentClassIter = authModel.listSubjectsWithProperty(ACL.agentClass, FOAF.Agent);
            try
            {
                agentClassIter.toList().forEach((auth) -> authModel.removeAll(auth, null, null));
            }
            finally
            {
                agentClassIter.close();
            }

            return getResponseBuilder(authModel).build();
        }
        catch (URISyntaxException ex)
        {
            throw new BadRequestException(ex);
        }
    }
    
    /**
     * Returns response builder for the given RDF model.
     * 
     * @param model RDF model
     * @return response builder
     */
    public Response.ResponseBuilder getResponseBuilder(Model model)
    {
        return new com.atomgraph.core.model.impl.Response(getRequest(), getHttpHeaders(),
                model,
                null,
                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
                getMediaTypes().getWritable(Model.class),
                null,
                null,
                new HTMLMediaTypePredicate()).
            getResponseBuilder();
    }

    /**
     * Returns the current request.
     *
     * @return request object
     */
    public Request getRequest()
    {
        return request;
    }

    /**
     * Returns the request headers.
     *
     * @return HTTP headers
     */
    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
    /**
     * Returns the current application.
     *
     * @return application resource
     */
    public EndUserDataspace getDataspace()
    {
        return application;
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
     * Returns URI info for the current request.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns media types registry.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    /**
     * Returns agent context.
     * 
     * @return agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }
    
}
