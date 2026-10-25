/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AccessModes;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.server.util.AuthorizationParams;
import com.atomgraph.linkeddatahub.server.util.DocumentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.Default;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.io.IOException;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import org.apache.jena.irix.IRIx;
import java.util.Set;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Authorization request filter.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 100) // has to execute after all AuthenticationFilters
public class AuthorizationFilter implements ContainerRequestFilter
{
    private static final Logger log = LoggerFactory.getLogger(AuthorizationFilter.class);

    /**
     * A mapping of HTTP methods to ACL access modes.
     */
    public static final Map<String, Resource> ACCESS_MODES = Map.of(
        HttpMethod.GET, ACL.Read,
        HttpMethod.HEAD, ACL.Read,
        HttpMethod.POST, ACL.Append,
        HttpMethod.PUT, ACL.Write,
        HttpMethod.DELETE, ACL.Write,
        HttpMethod.PATCH, ACL.Write
    );
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace>> app;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataset>> dataset;
    
    private ParameterizedSparqlString documentContextQuery, aclQuery;

    /**
     * Post-construct initialization.
     */
    @PostConstruct
    public void init()
    {
        documentContextQuery = new ParameterizedSparqlString(system.getDocumentContextQuery().toString());
        aclQuery = new ParameterizedSparqlString(getSystem().getACLQuery().toString());
    }
    
    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
        if (log.isDebugEnabled()) log.debug("Authorizing request URI: {}", request.getUriInfo().getRequestUri());

        Resource accessMode = getAccessMode(request.getMethod(), request.getHeaderString(HttpHeaders.IF_NONE_MATCH));
        if (log.isDebugEnabled()) log.debug("Request method: {} ACL access mode: {}", request.getMethod(), accessMode);
        if (accessMode == null)
        {
            if (log.isWarnEnabled()) log.warn("Skipping authentication/authorization, request method not recognized: {}", request.getMethod());
            return;
        }

        if (getDataspace().isPresent() && getDataspace().get().isReadAllowed())
        {
            if (request.getMethod().equals(HttpMethod.GET) || request.getMethod().equals(HttpMethod.HEAD)) // allow read-only methods
            {
                if (log.isTraceEnabled()) log.trace("Read methods are allowed on app, skipping authorization for request URI: {}", request.getUriInfo().getAbsolutePath());
                return;
            }
        }

        final Agent agent;
        if (request.getSecurityContext().getUserPrincipal() instanceof Agent) agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
        else agent = null; // public access

        Model authorizations = authorize(request, agent, accessMode);

        // HEAD is how a client learns a document's entity tag, and a conditional write needs one. Requiring
        // acl:Read for it would leave an agent that may write but not read unable to satisfy the precondition
        // the graph store demands of every write to a document that already exists - quietly turning acl:Write
        // into acl:Write AND acl:Read, a coupling no authorization document states. So a HEAD is granted to any
        // agent with a mode on the document: it carries no body, and a non-reader's is trimmed to the validator
        // and the modes by ResponseHeadersFilter. GET is untouched - content still needs acl:Read. acl:Append is
        // the least of the write modes, so a grant of either one covers it.
        if (authorizations == null && HttpMethod.HEAD.equals(request.getMethod()))
            authorizations = authorize(request, agent, ACL.Append);

        if (authorizations == null)
        {
            if (log.isTraceEnabled()) log.trace("Access not authorized for request URI: {} and access mode: {}", request.getUriInfo().getAbsolutePath(), accessMode);
            throw new AuthorizationException("Access not authorized for request URI", request.getUriInfo().getAbsolutePath(), accessMode);
        }
        else // authorization successful
            request.setProperty(AuthorizationContext.class.getCanonicalName(), new AuthorizationContext(authorizations));
    }
    
    /**
     * Returns authorization for the current request.
     * One decision serves both dataspaces: the document context query reads what the dataspace's store says of the
     * document - itself, its ancestors, its types and its owner, each from the document's own graph - and the ACL query
     * matches the authorizations in the admin dataset against it.
     * 
     * @param request current request
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(ContainerRequestContext request, Resource agent, Resource accessMode)
    {
        Resource accessTo = ResourceFactory.createResource(request.getUriInfo().getAbsolutePath().toString());

        // special case for PUT requests: if the document does not exist, check access on the *parent* URI instead -
        // acl:Write for a plain PUT, acl:Append for a create-only one (see getAccessMode()). Whether it exists is the
        // graph store's to say, the same answer put() acts on: having types is not the same thing, since the context query
        // also types an uploaded file, which has no graph of its own
        if (request.getMethod().equals(HttpMethod.PUT) && !getSystem().getServiceContext(getDataspace().get().getService()).getGraphStoreClient().containsModel(accessTo.getURI()))
        {
            // Use Jena's IRIx for RFC 3986-compliant resolution - java.net.URI.resolve("..") is non-compliant
            // (RFC 3986 section 5.2.4 step 2D requires ".." to be removed, but java.net.URI leaves it literal)
            Resource parent = ResourceFactory.createResource(IRIx.create(accessTo.getURI()).resolve("..").toString());
            log.debug("Requested document <{}> not found, falling back to parent URI <{}>", accessTo, parent);

            DocumentContext parentContext = getDocumentContext(parent);
            // only root and containers allow child documents
            if (Collections.disjoint(parentContext.getTypes(), Set.of(Default.Root, DH.Container))) return null;

            return authorize(parent, parentContext, agent, accessMode); // the document does not exist yet: its container decides
        }

        return authorize(accessTo, getDocumentContext(accessTo), agent, accessMode);
    }

    /**
     * Returns the agent's authorizations on a document, or null if none of them carries the access mode.
     * The authorizations returned are all of the agent's on the document, whatever their modes, so that the
     * <code>AuthorizationContext</code> knows every mode the agent has.
     *
     * @param accessTo document URI
     * @param context what the dataspace's store says of the document
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(Resource accessTo, DocumentContext context, Resource agent, Resource accessMode)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString(context.applyTo(getACLQuery().asQuery()).toString());
        Model authorizations = loadModel(getAdminService(), pss, new AuthorizationParams(getAdminBase(), accessTo, agent, context.isOwner(agent)).get());

        // access denied if the agent has no authorization to the requested document with the requested ACL mode
        if (getAuthorizationByMode(authorizations, accessMode) == null) return null;

        return authorizations;
    }

    /**
     * Returns what the dataspace's store says of a document, for the ACL query to match authorizations against.
     *
     * @param document document URI
     * @return document context
     */
    public DocumentContext getDocumentContext(Resource document)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, document);

        ResultSetRewindable result = loadResultSet(getDataspace().get().getService(), getDocumentContextQuery(), qsm);
        try
        {
            return new DocumentContext(result);
        }
        finally
        {
            result.close();
        }
    }
    
    /**
     * Returns the access mode a request requires.
     * The mode follows what the operation does, which the method alone does not always tell. A PUT with
     * <code>If-None-Match: *</code> can only create a document: the graph store refuses it with
     * <code>412 Precondition Failed</code> when the document exists, evaluating the precondition under the
     * document's write lock. Creating a document removes nothing - containment is stored in the child's own
     * graph, so the container's graph is untouched - and an access that only adds information is what
     * <code>acl:Append</code> is. A grant of <code>acl:Write</code> still covers it (see {@link AccessModes}).
     *
     * @param method HTTP method
     * @param ifNoneMatch <code>If-None-Match</code> header value, or <code>null</code>
     * @return ACL access mode, or <code>null</code> if the method is not recognized
     */
    public static Resource getAccessMode(String method, String ifNoneMatch)
    {
        if (HttpMethod.PUT.equals(method) && ifNoneMatch != null && ifNoneMatch.strip().equals("*")) return ACL.Append;

        return ACCESS_MODES.get(method);
    }

    /**
     * Returns an authorization from the given model whose mode covers the given access mode: the mode itself, or
     * a mode it is a subclass of in the ACL ontology - a grant of <code>acl:Write</code> covers <code>acl:Append</code>.
     * 
     * @param authModel model with authorizations
     * @param accessMode ACL access mode
     * @return authorization resource or null
     * @see AccessModes#covering(Resource)
     */
    public Resource getAuthorizationByMode(Model authModel, Resource accessMode)
    {
        return AccessModes.covering(accessMode).stream().
            flatMap(mode -> authModel.listResourcesWithProperty(ACL.mode, mode).toList().stream()).
            findFirst().
            orElse(null);
    }
    
    /**
     * Loads RDF graph from a service.
     * 
     * @param service SPARQL service
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return authorization graph (can be empty)
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
     */
    protected Model loadModel(com.atomgraph.linkeddatahub.model.Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), Model.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(Model.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), Model.class))
            {
                return cr.readEntity(Model.class);
            }
        }
    }
    
    /**
     * Loads SPARQL result set from a service.
     * 
     * @param service SPARQL service
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return authorization graph (can be empty)
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
     */
    protected ResultSetRewindable loadResultSet(com.atomgraph.linkeddatahub.model.Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), ResultSet.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), ResultSet.class))
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        }
    }
    
    /**
     * Returns the SPARQL service for agent data.
     *
     * @return service resource
     */
    protected Service getAdminService()
    {
        return getDataspace().get().canAs(EndUserDataspace.class) ?
            getDataspace().get().as(EndUserDataspace.class).getAdminDataspace().getService() :
            getDataspace().get().getService();
    }

    /**
     * Returns the base URI of the admin application.
     * Authorization data is always stored in the admin application's dataspace.
     *
     * @return admin application's base URI
     */
    protected Resource getAdminBase()
    {
        return getDataspace().get().canAs(EndUserDataspace.class) ?
            getDataspace().get().as(EndUserDataspace.class).getAdminDataspace().getBase() :
            getDataspace().get().getBase();
    }
    
    /**
     * Returns currently matched application.
     *
     * @return optional application resource
     */
    public Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace> getDataspace()
    {
        return app.get();
    }

    /**
     * Returns currently matched dataset (optional).
     * 
     * @return optional dataset resource
     */
    public Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataset> getDataset()
    {
        return dataset.get();
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns a query that loads what the dataspace's store says of a document.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getDocumentContextQuery()
    {
        return documentContextQuery.copy();
    }
    
    /**
     * Returns authorization query.
     * Used on the documents of either dataspace.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getACLQuery()
    {
        return aclQuery.copy();
    }
    
}