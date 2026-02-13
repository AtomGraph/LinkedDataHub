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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.PatchUpdateVisitor;
import com.atomgraph.linkeddatahub.server.util.WithGraphVisitor;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import java.net.URI;
import java.util.Optional;
import java.util.Set;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.modify.request.UpdateDeleteWhere;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.update.Update;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles batched SPARQL UPDATE requests.
 * Allows updating multiple graphs in a single request while maintaining security constraints.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class SPARQLUpdateEndpointImpl
{

    private static final Logger log = LoggerFactory.getLogger(SPARQLUpdateEndpointImpl.class);

    private final UriInfo uriInfo;
    private final Application application;
    private final Service service;
    private final SecurityContext securityContext;
    private final Optional<AgentContext> agentContext;

    /**
     * Constructs SPARQL UPDATE endpoint.
     *
     * @param uriInfo URI information of the current request
     * @param application current application
     * @param service SPARQL service of the current application
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     */
    @Inject
    public SPARQLUpdateEndpointImpl(@Context UriInfo uriInfo,
        Application application, Optional<Service> service,
        @Context SecurityContext securityContext, Optional<AgentContext> agentContext)
    {
        this.uriInfo = uriInfo;
        this.application = application;
        this.service = service.get();
        this.securityContext = securityContext;
        this.agentContext = agentContext;
    }

    /**
     * Handles batched SPARQL UPDATE requests.
     * Each operation in the batch must:
     * <ul>
     * <li>Be an INSERT/DELETE/WHERE or DELETE WHERE operation</li>
     * <li>Specify a WITH &lt;graph-uri&gt; clause</li>
     * <li>Not contain any GRAPH patterns</li>
     * </ul>
     * Authorization is checked for all graph URIs before execution.
     *
     * @param updateRequest SPARQL UPDATE request
     * @return response
     */
    @POST
    @Consumes(com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE)
    public Response post(UpdateRequest updateRequest)
    {
        if (updateRequest == null) throw new BadRequestException("SPARQL update not specified");
        if (log.isDebugEnabled()) log.debug("POST SPARQL UPDATE request with {} operations", updateRequest.getOperations().size());
        if (log.isDebugEnabled()) log.debug("SPARQL UPDATE string: {}", updateRequest.toString());

        // Validate operations and extract graph URIs
        WithGraphVisitor withGraphVisitor = new WithGraphVisitor();
        PatchUpdateVisitor patchUpdateVisitor = new PatchUpdateVisitor();

        for (Update update : updateRequest.getOperations())
        {
            // Only UpdateModify (INSERT/DELETE/WHERE) and UpdateDeleteWhere are supported
            if (!(update instanceof UpdateModify || update instanceof UpdateDeleteWhere))
                throw new WebApplicationException("Only INSERT/DELETE/WHERE and DELETE WHERE forms of SPARQL Update are supported", UNPROCESSABLE_ENTITY.getStatusCode());

            // Visit to check for GRAPH patterns (not allowed)
            update.visit(patchUpdateVisitor);

            // Visit to extract WITH clause graph URIs
            update.visit(withGraphVisitor);
        }

        // Check that no GRAPH keywords are used
        if (patchUpdateVisitor.containsNamedGraph())
        {
            if (log.isWarnEnabled()) log.warn("SPARQL update cannot contain the GRAPH keyword");
            throw new WebApplicationException("SPARQL update cannot contain the GRAPH keyword", UNPROCESSABLE_ENTITY.getStatusCode());
        }

        // Check that all operations have WITH clauses
        if (!withGraphVisitor.allHaveWithClause(updateRequest.getOperations().size()))
        {
            if (log.isWarnEnabled()) log.warn("All SPARQL update operations must specify a WITH <graph-uri> clause");
            throw new WebApplicationException("All SPARQL update operations must specify a WITH <graph-uri> clause", UNPROCESSABLE_ENTITY.getStatusCode());
        }

        Set<String> graphURIs = withGraphVisitor.getGraphURIs();
        if (log.isDebugEnabled()) log.debug("Found {} unique graph URIs in WITH clauses: {}", graphURIs.size(), graphURIs);

        // Check authorization for all graph URIs
        Resource agent = null;
        if (getSecurityContext().getUserPrincipal() instanceof com.atomgraph.linkeddatahub.model.auth.Agent)
            agent = ((com.atomgraph.linkeddatahub.model.auth.Agent)(getSecurityContext().getUserPrincipal()));

        for (String graphURI : graphURIs)
        {
            if (!isAuthorized(graphURI, agent))
            {
                if (log.isTraceEnabled()) log.trace("Access not authorized for graph URI: {} with access mode: {}", graphURI, ACL.Write);
                throw new AuthorizationException("Access not authorized for graph URI", URI.create(graphURI), ACL.Write);
            }
        }

        // All validations passed, execute the update
        if (log.isDebugEnabled()) log.debug("Executing SPARQL UPDATE on endpoint: {}", getService().getSPARQLEndpoint());
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        getService().getSPARQLClient().update(updateRequest, params);

        return Response.noContent().build();
    }

    /**
     * Checks if the current agent has Write access to the specified graph.
     *
     * @param graphURI graph URI to check
     * @param agent authenticated agent (can be null for public access)
     * @return true if authorized, false otherwise
     */
    protected boolean isAuthorized(String graphURI, Resource agent)
    {
        // Check if agent is the owner of the document - owners automatically get Write access
        if (agent != null && isOwner(graphURI, agent))
        {
            if (log.isDebugEnabled()) log.debug("Agent <{}> is the owner of <{}>, granting Write access", agent, graphURI);
            return true;
        }

        // For now, only owners can perform SPARQL updates
        // TODO: Implement full ACL authorization check similar to AuthorizationFilter.authorize()
        // This would require loading authorization data and checking for ACL.Write access mode

        return false;
    }

    /**
     * Checks if the given agent is the acl:owner of the document.
     *
     * @param graphURI the document URI
     * @param agent the agent whose ownership is checked
     * @return true if the agent is the owner, false otherwise
     */
    protected boolean isOwner(String graphURI, Resource agent)
    {
        if (agent == null) return false;

        try
        {
            Model graphModel = getService().getGraphStoreClient().getModel(graphURI);
            Resource graphResource = graphModel.createResource(graphURI);

            return graphResource.hasProperty(ACL.owner, agent);
        }
        catch (Exception ex)
        {
            if (log.isWarnEnabled()) log.warn("Could not check ownership for graph <{}>: {}", graphURI, ex.getMessage());
            return false;
        }
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
     * Returns the current application.
     *
     * @return application resource
     */
    public Application getApplication()
    {
        return application;
    }

    /**
     * Returns the SPARQL service.
     *
     * @return service
     */
    public Service getService()
    {
        return service;
    }

    /**
     * Returns the security context.
     *
     * @return security context
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }

    /**
     * Returns the authenticated agent's context.
     *
     * @return optional agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }

}
