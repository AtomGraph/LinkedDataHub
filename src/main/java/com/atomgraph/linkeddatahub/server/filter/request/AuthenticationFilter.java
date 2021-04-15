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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import java.io.IOException;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.Response;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract JAX-RS filter base class for authentication request filters.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class AuthenticationFilter implements ContainerRequestFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(AuthenticationFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject Optional<com.atomgraph.linkeddatahub.apps.model.Application> app;

    public abstract String getScheme();
    
    public abstract void login(com.atomgraph.linkeddatahub.apps.model.Application app, ContainerRequestContext request);

    public abstract void logout(com.atomgraph.linkeddatahub.apps.model.Application app, ContainerRequestContext request);
    
    public abstract Resource authenticate(ContainerRequestContext request);

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
        if (log.isDebugEnabled()) log.debug("Authenticating request URI: {}", request.getUriInfo().getRequestUri());

        if (getApplication().isEmpty()) return; // skip filter if no application has matched
        if (request.getSecurityContext().getUserPrincipal() != null) return; // skip filter if agent already authorized

        //if (isLogoutForced(request, getScheme())) logout(getApplication(), request);
        
        final Resource agent = authenticate(request);
        if (agent == null) return; // skip to the next filter if agent could not be retrieved with this one

        // imitate type inference, otherwise we'll get Jena's polymorphism exception
        request.setSecurityContext(new AgentContext(getScheme(), agent.addProperty(RDF.type, LACL.Agent).as(Agent.class)));
    }
    
    protected Service getAgentService()
    {
        return getApplication().get().canAs(EndUserApplication.class) ?
            getApplication().get().as(EndUserApplication.class).getAdminApplication().getService() :
            getApplication().get().getService();
    }
    
    /**
     * Loads authorization graph from the admin service.
     * 
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @param service SPARQL service
     * @return authorization graph (can be empty)
     * @see com.atomgraph.linkeddatahub.vocabulary.APLC#authQuery
     */
    protected Model loadModel(ParameterizedSparqlString pss, QuerySolutionMap qsm, com.atomgraph.linkeddatahub.model.Service service)
    {
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        if (service == null) throw new IllegalArgumentException("Service cannot be null");

        // send query bindings separately from the query if the service supports the Sesame protocol
        if (service.getSPARQLClient() instanceof SesameProtocolClient)
            try (Response cr = ((SesameProtocolClient)service.getSPARQLClient()). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), Model.class, qsm))
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
     
    public boolean isLoginForced(ContainerRequestContext request, String scheme)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
        
        if (request.getUriInfo().getQueryParameters().getFirst(APLT.login.getLocalName()) != null)
            return request.getUriInfo().getQueryParameters().getFirst(APLT.login.getLocalName()).equalsIgnoreCase(scheme);
        
        return false;
    }
    
    public boolean isLogoutForced(ContainerRequestContext request, String scheme)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");

        if (request.getUriInfo().getQueryParameters().getFirst(APLT.logout.getLocalName()) != null)
            return request.getUriInfo().getQueryParameters().getFirst(APLT.logout.getLocalName()).equalsIgnoreCase(scheme);
        
        return false;
    }
    
    public Optional<Application> getApplication()
    {
        return app;
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

}