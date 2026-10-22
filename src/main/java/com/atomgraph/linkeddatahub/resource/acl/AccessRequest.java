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

import com.atomgraph.core.exception.ConfigurationException;
import static com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace.AUTHORIZATION_REQUEST_PATH;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import jakarta.inject.Inject;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Resource for handling ACL access requests.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AccessRequest
{
    
    private static final Logger log = LoggerFactory.getLogger(AccessRequest.class);
    
    private final EndUserDataspace application;
    private final Optional<AgentContext> agentContext;
    private final String emailSubject;
    private final String emailText;
    private final UriBuilder authRequestContainerUriBuilder;
    private final com.atomgraph.linkeddatahub.Application system;
    
    /**
     * Constructs an AccessRequest resource handler.
     * 
     * @param application current application
     * @param agentContext optional agent context
     * @param system system application
     * @param servletConfig servlet configuration
     */
    @Inject
    public AccessRequest(com.atomgraph.linkeddatahub.dataspaces.model.Dataspace application, Optional<AgentContext> agentContext,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        if (!application.canAs(EndUserDataspace.class)) throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");
        this.application = application.as(EndUserDataspace.class);
        this.agentContext = agentContext;
        this.system = system;

        authRequestContainerUriBuilder = this.application.getAdminDataspace().getUriBuilder().path(AUTHORIZATION_REQUEST_PATH);
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailText));

    }

    /**
     * Implements the HTTP GET method.
     *
     * @return response object
     */
    @GET
    public Response get()
    {
        throw new NotAllowedException("GET is not allowed on this endpoint", HttpMethod.POST, new String[]{ HttpMethod.OPTIONS });
    }

    /**
     * Implements the HTTP POST method for submitting access requests.
     * Every <code>acl:Authorization</code> in the payload becomes an authorization request document in the admin
     * application. All of them are validated before any is written: each must name the authenticated agent as its
     * <code>acl:agent</code>.
     * The response is <code>201 Created</code>; when several request documents are created, <code>Location</code>
     * points at one of them.
     *
     * @param model RDF model with access request data
     * @return response object
     */
    @POST
    public Response post(Model model)
    {
        List<Resource> authorizations = getAuthorizations(model);
        if (authorizations.isEmpty()) throw new WebApplicationException("The access request contains no acl:Authorization", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity

        for (Resource authorization : authorizations)
        {
            Resource agent = authorization.getPropertyResourceValue(ACL.agent);
            if (agent == null) throw new WebApplicationException("The requested acl:Authorization has no acl:agent", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
            if (getAgentContext().isEmpty() || !agent.equals(getAgentContext().get().getAgent()))
                throw new ForbiddenException("Access can only be requested for the authenticated agent");
        }

        Agent agent = getAgentContext().get().getAgent();
        String humanReadableName = getAgentsHumanReadableName(agent);
        String accessRequestLabel = humanReadableName != null ? "Access request by " + humanReadableName : null; // TO-DO: localize the string
        URI location = null;

        for (Resource authorization : authorizations)
        {
            URI graphUri = getAuthRequestContainerUriBuilder().path(UUID.randomUUID().toString() + "/").build(); // URI of the new access request graph
            if (location == null) location = graphUri;
            Model requestModel = ModelFactory.createDefaultModel();

            Resource accessTo = authorization.getPropertyResourceValue(ACL.accessTo);
            Resource accessToClass = authorization.getPropertyResourceValue(ACL.accessToClass);

            Resource accessRequest = requestModel.createResource().
                addProperty(RDF.type, LACL.AuthorizationRequest).
                addProperty(LACL.requestAgent, agent).
                addLiteral(DCTerms.created, GregorianCalendar.getInstance());
            if (accessRequestLabel != null) accessRequest.addLiteral(RDFS.label, accessRequestLabel);

            // add all requested access modes
            StmtIterator modeIt = authorization.listProperties(ACL.mode);
            try
            {
                modeIt.forEachRemaining(stmt -> accessRequest.addProperty(LACL.requestMode, stmt.getResource()));
            }
            finally
            {
                modeIt.close();
            }

            if (accessTo != null) accessRequest.addProperty(LACL.requestAccessTo, accessTo);
            if (accessToClass != null) accessRequest.addProperty(LACL.requestAccessToClass, accessToClass);

            // attach document to parent explicitly because this class extends GraphStoreImpl and not Graph (which would handle it implicitly)
            Resource doc = requestModel.createResource(graphUri.toString()).
                addProperty(RDF.type, DH.Item).
                addProperty(SIOC.HAS_CONTAINER, requestModel.createResource(getAuthRequestContainerUriBuilder().build().toString())).
                addProperty(FOAF.primaryTopic, accessRequest);
            if (accessRequestLabel != null) doc.addLiteral(DCTerms.title, accessRequestLabel);

//            try
//            {
//                sendEmail(owner, accessRequest);
//            }
//            catch (MessagingException | UnsupportedEncodingException ex)
//            {
//                if (log.isErrorEnabled()) log.error("Could not send access request email to Agent: {}", getAgentContext().get().getAgent().getURI());
//            }

            new Skolemizer(graphUri.toString()).apply(requestModel);
            // store access request in the admin service
            getSystem().getServiceContext(getDataspace().getAdminDataspace().getService()).getGraphStoreClient().add(graphUri.toString(), requestModel);
        }

        return Response.created(location).build();
    }

    /**
     * Returns the authorizations requested in the payload.
     *
     * @param model RDF model with access request data
     * @return list of authorization resources
     */
    public List<Resource> getAuthorizations(Model model)
    {
        ResIterator it = model.listResourcesWithProperty(RDF.type, ACL.Authorization);
        try
        {
            return it.toList();
        }
        finally
        {
            it.close();
        }
    }

    /**
     * Returns a human-readable name for the agent.
     * 
     * @param agent the agent
     * @return human-readable name or null if not available
     */
    public String getAgentsHumanReadableName(Agent agent)
    {
        if (agent.hasProperty(FOAF.givenName) && agent.hasProperty(FOAF.familyName))
            return agent.getProperty(FOAF.givenName).getString() + " " + agent.getProperty(FOAF.familyName).getString();
        
        if (agent.hasProperty(FOAF.name)) return agent.getProperty(FOAF.name).getString();
        
        return null;
    }

    /**
     * Returns the current application.
     *
     * @return end-user application
     */
    public EndUserDataspace getDataspace()
    {
        return application;
    }
    
    /**
     * Returns the URI builder for authorization requests.
     * 
     * @return URI builder
     */
    public UriBuilder getAuthRequestContainerUriBuilder()
    {
        return authRequestContainerUriBuilder.clone();
    }
 
    /**
     * Returns the agent context of the current request.
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

}
