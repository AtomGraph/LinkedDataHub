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

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.server.vocabulary.LDT;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
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
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.vocabulary.RDFS;
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
    public static final Map<String, Resource> ACCESS_MODES;
    static
    {
        final Map<String, Resource> accessModes = new HashMap<>();
        
        accessModes.put(HttpMethod.GET, ACL.Read);
        accessModes.put(HttpMethod.HEAD, ACL.Read);
        accessModes.put(HttpMethod.POST, ACL.Append);
        accessModes.put(HttpMethod.PUT, ACL.Write);
        accessModes.put(HttpMethod.DELETE, ACL.Write);
        accessModes.put(HttpMethod.PATCH, ACL.Write);
        
        ACCESS_MODES = Collections.unmodifiableMap(accessModes);
    }
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> app;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Dataset>> dataset;
    
    private ParameterizedSparqlString aclQuery, ownerAclQuery;

    /**
     * Post-construct initialization.
     */
    @PostConstruct
    public void init()
    {
        aclQuery = new ParameterizedSparqlString(getSystem().getACLQuery().toString());
        ownerAclQuery = new ParameterizedSparqlString(getSystem().getOwnerACLQuery().toString());
    }
    
    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
        if (log.isDebugEnabled()) log.debug("Authorizing request URI: {}", request.getUriInfo().getRequestUri());

        // allow proxied URIs that are mapped to local files
        if (request.getMethod().equals(HttpMethod.GET) && request.getUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName()))
        {
            String proxiedURI = request.getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName());
            if (getSystem().getDataManager().isMapped(proxiedURI)) return;
        }

        Resource accessMode = ACCESS_MODES.get(request.getMethod());
        if (log.isDebugEnabled()) log.debug("Request method: {} ACL access mode: {}", request.getMethod(), accessMode);
        if (accessMode == null)
        {
            if (log.isWarnEnabled()) log.warn("Skipping authentication/authorization, request method not recognized: {}", request.getMethod());
            return;
        }
        
        if (getApplication().isReadAllowed())
        {
            if (request.getMethod().equals(HttpMethod.GET) || request.getMethod().equals(HttpMethod.HEAD)) // allow read-only methods
            {
                if (log.isTraceEnabled()) log.trace("Read methods are allowed on app, skipping authorization for request URI: {}", request.getUriInfo().getAbsolutePath());
                return;
            }
        }

        if (getDataset().isPresent()) return; // skip proxied dataspaces

        final Agent agent;
        if (request.getSecurityContext().getUserPrincipal() instanceof Agent) agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
        else agent = null; // public access

        Resource authorization = authorize(request, agent, accessMode);
        if (authorization == null)
        {
            if (log.isTraceEnabled()) log.trace("Access not authorized for request URI: {} and access mode: {}", request.getUriInfo().getAbsolutePath(), accessMode);
            throw new AuthorizationException("Access not authorized for request URI", request.getUriInfo().getAbsolutePath(), accessMode);
        }
        else // authorization successful
            request.setProperty(AuthorizationContext.class.getCanonicalName(), new AuthorizationContext(authorization.getModel()));
    }
    
    /**
     * Builds solution map for the authorization query.
     * 
     * @param absolutePath request URL without query string
     * @param agent agent resource or null
     * @return solution map
     */
    public QuerySolutionMap getAuthorizationParams(Resource absolutePath, Resource agent)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, absolutePath);
//        qsm.add(LDT.Ontology.getLocalName(), getApplication().getOntology());
        qsm.add(LDT.base.getLocalName(), getApplication().getBase());
        
//        if (!absolutePath.equals(getApplication().getBase())) // enable $Container pattern, unless the Root document is requested
//        {
//            URI container = URI.create(absolutePath.getURI()).resolve("..");
//            qsm.add(SIOC.CONTAINER.getLocalName(), ResourceFactory.createResource(container.toString()));
//        }
//        else // disable $Container pattern
//            qsm.add(SIOC.CONTAINER.getLocalName(), RDFS.Resource);

        if (agent != null)
        {
            qsm.add("AuthenticatedAgentClass", ACL.AuthenticatedAgent); // enable AuthenticatedAgent UNION branch
            qsm.add("agent", agent);
        }
        else
        {
            qsm.add("AuthenticatedAgentClass", RDFS.Resource); // disable AuthenticatedAgent UNION branch
            qsm.add("agent", RDFS.Resource); // disables UNION branch with $agent
        }
        
        return qsm;
    }
    
    /**
     * Returns authorization for the current request.
     * 
     * @param request current request
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorization resource or null
     */
    public Resource authorize(ContainerRequestContext request, Resource agent, Resource accessMode)
    {
        Resource accessTo = ResourceFactory.createResource(request.getUriInfo().getAbsolutePath().toString());

        QuerySolutionMap docTypeQsm = new QuerySolutionMap();
        docTypeQsm.add(SPIN.THIS_VAR_NAME, accessTo);
        ResultSet docTypes = loadResultSet(getApplication().getService(), getDocumentTypeQuery(), docTypeQsm);
        
        try
        {
            if (!docTypes.hasNext()) // if the document resource has no types, we assume the document does not exist
            {
                // special case for PUT requests to non-existing document: allow if the agent has acl:Write acess to the *parent* URI
                if (request.getMethod().equals(HttpMethod.PUT))
                {
                    URI parentURI = URI.create(accessTo.getURI()).resolve("..");
                    log.debug("Requested document <{}> not found, falling back to parent URI <{}>", accessTo, parentURI);
                    accessTo = ResourceFactory.createResource(parentURI.toString());
                    
                    docTypeQsm = new QuerySolutionMap();
                    docTypeQsm.add(SPIN.THIS_VAR_NAME, accessTo);
                    docTypes.close();
                    docTypes = loadResultSet(getApplication().getService(), getDocumentTypeQuery(), docTypeQsm);
                }
                else return null;
            }

            ParameterizedSparqlString pss = getApplication().canAs(EndUserApplication.class) ? getACLQuery() : getOwnerACLQuery();
            Query query = setResultSetValues(pss.asQuery(), docTypes);
            pss = new ParameterizedSparqlString(query.toString()); // make sure VALUES are now part of the query string
            assert pss.toString().contains("VALUES");

            Model authModel = loadModel(getAdminService(), pss, getAuthorizationParams(accessTo, agent));
            return authorize(authModel, accessMode, docTypes);
        }
        finally
        {
            docTypes.close();
        }
    }
    
    /**
     * Authorizes current request by applying solution map on the authorization query and executing it.
     * 
     * @param authModel model with authorizations
     * @param accessMode ACL access mode
     * @param docTypes document types
     * @return authorization resource or null
     */
    public Resource authorize(Model authModel, Resource accessMode, ResultSet docTypes)
    {
        ResIterator it = authModel.listResourcesWithProperty(ACL.mode, accessMode);
        try
        {
            return it.nextOptional().orElse(null);
        }
        finally
        {
            it.close();
        }        
    }
    
    /**
     * Loads RDF graph from a service.
     * 
     * @param service SPARQL service
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return authorization graph (can be empty)
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#authQuery
     */
    protected Model loadModel(com.atomgraph.linkeddatahub.model.Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        // send query bindings separately from the query if the service supports the Sesame protocol
        if (service.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), Model.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(Model.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = service.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
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
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#authQuery
     */
    protected ResultSet loadResultSet(com.atomgraph.linkeddatahub.model.Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        // send query bindings separately from the query if the service supports the Sesame protocol
        if (service.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), ResultSet.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(ResultSet.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = service.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), ResultSet.class))
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        }
    }
    
    /**
     * Converts a SPARQL result set into a <code>VALUES</code> block.
     * 
     * @param query SPARQL query
     * @param resultSet result set
     * @return query with appended values
     */
    public Query setResultSetValues(Query query, ResultSet resultSet)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");
        if (resultSet == null) throw new IllegalArgumentException("ResultSet cannot be null");
        
        List<Var> vars = resultSet.getResultVars().stream().map(Var::alloc).toList();
        List<Binding> values = new ArrayList<>();
        while (resultSet.hasNext())
            values.add(resultSet.nextBinding());

        query.setValuesDataBlock(vars, values);
        return query;
    }
    
    /**
     * Returns a query that selects the types of a given document.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getDocumentTypeQuery()
    {
        // TO-DO: move to web.xml
        return new ParameterizedSparqlString("SELECT  ?Type\n" +
"WHERE\n" +
"  {   { GRAPH ?this\n" +
"          { ?this  a  ?Type }\n" +
"      }\n" +
"    UNION\n" +
"      { { GRAPH ?g\n" +
"            { ?this  a  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject> ;\n" +
"                     a  ?Type\n" +
"            }\n" +
"        }\n" +
"      }\n" +
"  }");
    }
    
    /**
     * Returns the SPARQL service for agent data.
     * 
     * @return service resource
     */
    protected Service getAdminService()
    {
        return getApplication().canAs(EndUserApplication.class) ?
            getApplication().as(EndUserApplication.class).getAdminApplication().getService() :
            getApplication().getService();
    }
    
    /**
     * Returns currently matched application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return app.get();
    }

    /**
     * Returns currently matched dataset (optional).
     * 
     * @return optional dataset resource
     */
    public Optional<com.atomgraph.linkeddatahub.apps.model.Dataset> getDataset()
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
     * Returns authorization query.
     * Used on end-user applications.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getACLQuery()
    {
        return aclQuery.copy();
    }

    /**
     * Returns owner authorization query.
     * Used on admin applications.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getOwnerACLQuery()
    {
        return ownerAclQuery.copy();
    }
    
}
