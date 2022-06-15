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
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.vocabulary.LDT;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import javax.annotation.PostConstruct;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Response;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
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
    @Inject javax.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> app;
    @Inject javax.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Dataset>> dataset;
    
    private ParameterizedSparqlString authQuery, ownerAuthQuery;

    /**
     * Post-construct initialization.
     */
    @PostConstruct
    public void init()
    {
        authQuery = new ParameterizedSparqlString(getSystem().getAuthQuery().toString());
        ownerAuthQuery = new ParameterizedSparqlString(getSystem().getOwnerAuthQuery().toString());
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
        
        if (getApplication().isReadOnly())
        {
            if (request.getMethod().equals(HttpMethod.GET) || request.getMethod().equals(HttpMethod.HEAD)) // allow read-only methods
            {
                if (log.isTraceEnabled()) log.trace("App is read-only, skipping authorization for request URI: {}", request.getUriInfo().getAbsolutePath());
                return;
            }

            // throw 403 exception otherwise
            if (log.isTraceEnabled()) log.trace("Write access not authorized (app is read-only) for request URI: {}", request.getUriInfo().getAbsolutePath());
            throw new AuthorizationException("Write access not authorized (app is read-only)", request.getUriInfo().getAbsolutePath(), accessMode);
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
     * @param accessMode ACL access mode
     * @return solution map
     */
    public QuerySolutionMap getAuthorizationParams(Resource absolutePath, Resource agent, Resource accessMode)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, absolutePath);
        qsm.add("Mode", accessMode);
        qsm.add(LDT.Ontology.getLocalName(), getApplication().getOntology());
        qsm.add(LDT.base.getLocalName(), getApplication().getBase());
        
        if (agent != null)
        {
            qsm.add("AuthenticatedAgentClass", ACL.AuthenticatedAgent); // enable AuthenticatedAgent UNION branch
            qsm.add("agent", agent);
        }
        else
        {
            qsm.add("AuthenticatedAgentClass", RDFS.Resource); // disable AuthenticatedAgent UNION branch
            qsm.add("agent", RDFS.Resource); // disables UNION branch with ?agent
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
        return authorize(getAuthorizationParams(ResourceFactory.createResource(request.getUriInfo().getAbsolutePath().toString()), agent, accessMode));
    }
    
    /**
     * Authorizes current request by applying solution map on the authorization query and executing it.
     * 
     * @param qsm solution map
     * @return authorization resource or null
     */
    public Resource authorize(QuerySolutionMap qsm)
    {
        Model authModel = loadAuth(qsm);
        
        // type check will not work on LACL subclasses without InfModel
        Resource authorization = getResourceByPropertyValue(authModel, ACL.mode, null);
        if (authorization == null) authorization = getResourceByPropertyValue(authModel, ResourceFactory.createProperty(LACL.NS + "accessProperty"), null); // creator access
            
        return authorization;
    }

    /**
     * Loads authorization model.
     * 
     * @param qsm solution map
     * @return authorization model
     */
    protected Model loadAuth(QuerySolutionMap qsm)
    {
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");

        final ParameterizedSparqlString pss = getApplication().canAs(EndUserApplication.class) ? getAuthQuery() : getOwnerAuthQuery();
        
        if (getApplication().canAs(EndUserApplication.class))
            pss.setIri(SD.endpoint.getLocalName(), getApplication().getService().getSPARQLEndpoint().toString()); // needed for federation with the end-user endpoint

        return loadModel(getAdminService(), pss, qsm);
    }
    
    /**
     * Loads authorization graph from the admin service.
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
     * Returns resource which has a specified property with a specified value, from the specified model.
     * If there are multiple matching resources, one is selected in undefined order.
     * 
     * @param model model
     * @param property property
     * @param value value
     * @return resource or null, if none matched
     */
    protected Resource getResourceByPropertyValue(Model model, Property property, RDFNode value)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (property == null) throw new IllegalArgumentException("Property cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(property, value);
        
        try
        {
            if (it.hasNext()) return it.next();
        }
        finally
        {
            it.close();
        }

        return null;
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
    public ParameterizedSparqlString getAuthQuery()
    {
        return authQuery.copy();
    }

    /**
     * Returns owner authorization query.
     * Used on admin applications.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getOwnerAuthQuery()
    {
        return ownerAuthQuery.copy();
    }
    
}
