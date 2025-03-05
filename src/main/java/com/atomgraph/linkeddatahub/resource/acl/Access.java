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

import com.atomgraph.core.MediaTypes;
import static com.atomgraph.core.model.SPARQLEndpoint.DEFAULT_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.NAMED_GRAPH_URI;
import static com.atomgraph.core.model.SPARQLEndpoint.QUERY;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.atomgraph.server.vocabulary.LDT;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Optional;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDFS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Access extends com.atomgraph.core.model.impl.SPARQLEndpointImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(Access.class);

    private final UriInfo uriInfo;
    private final Application application;
    private final Optional<AgentContext> agentContext;
    private final ParameterizedSparqlString aclQuery, ownerAclQuery;
    
    /**
     * Constructs endpoint from the in-memory ontology model.
     * 
     * @param request current request
     * @param uriInfo current request's URI info
     * @param application current end-user application
     * @param ontology application's ontology
     * @param mediaTypes registry of readable/writable media types
     * @param securityContext JAX-RS security context
     * @param agentContext agent context
     * @param system system application
     */
    @Inject
    public Access(@Context Request request, @Context UriInfo uriInfo, 
            Application application, Optional<Ontology> ontology, MediaTypes mediaTypes,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(request, application.getService(), mediaTypes);
        if (!application.canAs(AdminApplication.class)) throw new IllegalStateException("The " + getClass() + " endpoint is only available on admin applications");

        this.uriInfo = uriInfo;
        this.application = application;
        this.agentContext = agentContext;
        aclQuery = new ParameterizedSparqlString(system.getACLQuery().toString());
        ownerAclQuery = new ParameterizedSparqlString(system.getOwnerACLQuery().toString());
    }
    
    @Override
    @GET
    public Response get(@QueryParam(QUERY) Query query,
            @QueryParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @QueryParam(NAMED_GRAPH_URI) List<URI> namedGraphUris)
    {
        final Agent agent = getAgentContext().map(AgentContext::getAgent).orElse(null);
//        final Agent agent = ModelFactory.createDefaultModel().
//                createResource(getUriInfo().getQueryParameters().getFirst("agent")).
//                addProperty(RDF.type, FOAF.Agent).
//                as(Agent.class);
                
        final ParameterizedSparqlString pss = getApplication().canAs(EndUserApplication.class) ? getACLQuery() : getOwnerACLQuery();
        
        try
        {
            if (!getUriInfo().getQueryParameters().containsKey(SPIN.THIS_VAR_NAME)) throw new BadRequestException();
            URI accessTo = new URI(getUriInfo().getQueryParameters().getFirst(SPIN.THIS_VAR_NAME)); // ?this query param needs to be passed

            pss.setParams(getAuthorizationParams(ResourceFactory.createResource(accessTo.toString()), agent, null));
            query = pss.asQuery(); // override any supplied query with the ACL one
                    
            return super.get(query, defaultGraphUris, namedGraphUris);
        }
        catch (URISyntaxException ex)
        {
            throw new BadRequestException(ex);
        }
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
        qsm.add(LDT.Ontology.getLocalName(), getApplication().getOntology());
        qsm.add(LDT.base.getLocalName(), getApplication().getBase());

        if (accessMode != null) qsm.add("Mode", accessMode);
        
        if (!absolutePath.equals(getApplication().getBase())) // enable $Container pattern, unless the Root document is requested
        {
            URI container = URI.create(absolutePath.getURI()).resolve("..");
            qsm.add(SIOC.CONTAINER.getLocalName(), ResourceFactory.createResource(container.toString()));
        }
        else // disable $Container pattern
            qsm.add(SIOC.CONTAINER.getLocalName(), RDFS.Resource);

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
     * Returns the current application.
     * 
     * @return application resource
     */
    public Application getApplication()
    {
        return application;
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
     * Returns agent context.
     * 
     * @return agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
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

    private Exception BadRequestException(URISyntaxException ex) {
        throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
    }
    
}
