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
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.AuthorizationParams;
import com.atomgraph.linkeddatahub.server.util.SetResultSetValues;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
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
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;
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
    private final ParameterizedSparqlString documentTypeQuery, aclQuery, ownerAclQuery;
    
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
        documentTypeQuery = new ParameterizedSparqlString(system.getDocumentTypeQuery().toString());
        aclQuery = new ParameterizedSparqlString(system.getACLQuery().toString());
        ownerAclQuery = new ParameterizedSparqlString(system.getOwnerACLQuery().toString());
    }
    
    @Override
    @GET
    public Response get(@QueryParam(QUERY) Query unused,
            @QueryParam(DEFAULT_GRAPH_URI) List<URI> defaultGraphUris, @QueryParam(NAMED_GRAPH_URI) List<URI> namedGraphUris)
    {
        final Agent agent = getAgentContext().map(AgentContext::getAgent).orElse(null);
//        final Agent agent = ModelFactory.createDefaultModel().
//                createResource(getUriInfo().getQueryParameters().getFirst("agent")).
//                addProperty(RDF.type, FOAF.Agent).
//                as(Agent.class);
                
        //final ParameterizedSparqlString pss = getApplication().canAs(EndUserApplication.class) ? getACLQuery() : getOwnerACLQuery();        
        try
        {
            if (!getUriInfo().getQueryParameters().containsKey(SPIN.THIS_VAR_NAME)) throw new BadRequestException("?this query param is not provided");
            
            Resource accessTo = ResourceFactory.createResource(new URI(getUriInfo().getQueryParameters().getFirst(SPIN.THIS_VAR_NAME)).toString()); // ?this query param needs to be passed
            if (log.isDebugEnabled()) log.debug("Loading current agent's authorizations for the <{}> document", accessTo);
            
            QuerySolutionMap thisQsm = new QuerySolutionMap();
            thisQsm.add(SPIN.THIS_VAR_NAME, accessTo);
            ParameterizedSparqlString typePss = getDocumentTypeQuery();
            typePss.setParams(thisQsm);
            
            ResultSetRewindable docTypesResult = getEndpointAccessor().select(typePss.asQuery(), null, null);
            try
            {
                final ParameterizedSparqlString authPss = getACLQuery();
                authPss.setParams(new AuthorizationParams(getApplication().getBase(), accessTo, agent).get());
                Query authQuery = new SetResultSetValues().apply(authPss.asQuery(), docTypesResult);
                assert authQuery.toString().contains("VALUES");

                Model authModel = getEndpointAccessor().loadModel(authQuery, defaultGraphUris, namedGraphUris);
                // special case where the agent is the owner of the requested document - automatically grant acl:Read/acl:Append/acl:Write access
                if (isOwner(accessTo, agent))
                {
                    log.debug("Agent <{}> is the owner of <{}>, granting acl:Read/acl:Append/acl:Write access", agent, accessTo);
                    authModel.add(createOwnerAuthorization(accessTo, agent).getModel());
                }
                
                return getResponseBuilder(authModel).build();
            }
            finally
            {
                docTypesResult.close();
            }
        }
        catch (URISyntaxException ex)
        {
            throw new BadRequestException(ex);
        }
    }
    
    /**
     * Checks if the given agent is the <code>acl:owner</code> of the document.
     * 
     * @param accessTo the document URI
     * @param agent the agent whose ownership is checked.
     * @return true if the agent is the owner, false otherwise.
     */
    protected boolean isOwner(Resource accessTo, Resource agent)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, accessTo);
        ParameterizedSparqlString pss = getDocumentOwnerQuery();
        pss.setParams(qsm);

        ResultSetRewindable docOwnerResult = getEndpointAccessor().select(pss.asQuery(), null, null);
        //loadResultSet(getApplication().getService(), getDocumentOwnerQuery(), qsm); // could use ASK query in principle
        try
        {
            return isOwner(docOwnerResult, agent);
        }
        finally
        {
            docOwnerResult.close();
        }
    }
    
    /**
     * Checks if the given agent is the <code>acl:owner</code> of the document.
     * 
     * @param docOwnerResult the result set containing document metadata
     * @param agent the agent whose ownership is checked
     * @return true if the agent is the owner, false otherwise.
     */
    protected boolean isOwner(ResultSetRewindable docOwnerResult, Resource agent)
    {
        if (docOwnerResult == null) throw new IllegalArgumentException("ResultSet cannot be null");
        if (agent == null) throw new IllegalArgumentException("Agent resource cannot be null");

        Resource owner = null;

        while (docOwnerResult.hasNext())
        {
            QuerySolution qs = docOwnerResult.next();
            if (owner == null && qs.contains("owner")) owner = qs.getResource("owner");
        }

        docOwnerResult.reset();

        return owner != null && owner.equals(agent);
    }
    
    /**
     * Creates a special <code>acl:Authorization</code> resource for an owner.
     * @param accessTo requested URI
     * @param agent authenticated agent
     * @return authorization resource
     */
    public Resource createOwnerAuthorization(Resource accessTo, Resource agent)
    {
        if (accessTo == null) throw new IllegalArgumentException("Document resource cannot be null");
        if (agent == null) throw new IllegalArgumentException("Agent resource cannot be null");

        return ModelFactory.createDefaultModel().
                createResource().
                addProperty(RDF.type, ACL.Authorization).
                addProperty(RDF.type, LACL.OwnerAuthorization).
                addProperty(ACL.accessTo, accessTo).
                addProperty(ACL.agent, agent).
                addProperty(ACL.mode, ACL.Read).
                addProperty(ACL.mode, ACL.Write).
                addProperty(ACL.mode, ACL.Append);
    }
    
    /**
     * Returns the SPARQL service for end-user data.
     * 
     * @return service resource
     */
    protected Service getEndUserService()
    {
        return getApplication().canAs(AdminApplication.class) ?
            getApplication().as(AdminApplication.class).getEndUserApplication().getService() :
            getApplication().getService();
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
    
    /**
     * Returns a query that loads document type and owner metadata.
     * 
     * @return SPARQL string
     */
    public ParameterizedSparqlString getDocumentTypeQuery()
    {
        return documentTypeQuery.copy();
    }
    
    public ParameterizedSparqlString getDocumentOwnerQuery()
    {
        return new ParameterizedSparqlString("PREFIX  acl:  <http://www.w3.org/ns/auth/acl#>\n" +
"\n" +
"SELECT  ?owner\n" +
"WHERE\n" +
"  { GRAPH $this\n" +
"      { $this  acl:owner  ?owner }\n" +
"  }");
    }
    
}
