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
import static com.atomgraph.linkeddatahub.apps.model.AdminApplication.AUTHORIZATION_REQUEST_PATH;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
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
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import java.util.GregorianCalendar;
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
    
    private final EndUserApplication application;
    private final Optional<AgentContext> agentContext;
    private final String emailSubject;
    private final String emailText;
    private final UriBuilder authRequestContainerUriBuilder;
    
    /**
     * Constructs an AccessRequest resource handler.
     * 
     * @param request HTTP request context
     * @param uriInfo URI information context
     * @param application current application
     * @param agentContext optional agent context
     * @param system system application
     * @param servletConfig servlet configuration
     */
    @Inject
    public AccessRequest(@Context Request request, @Context UriInfo uriInfo,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<AgentContext> agentContext,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        if (!application.canAs(EndUserApplication.class)) throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");
        this.application = application.as(EndUserApplication.class);
        this.agentContext = agentContext;
        
        authRequestContainerUriBuilder = this.application.getAdminApplication().getUriBuilder().path(AUTHORIZATION_REQUEST_PATH);
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailText));

    }
    
    @GET
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        throw new NotAllowedException("GET is not allowed on this endpoint");
    }
    
    @POST
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        ResIterator it = model.listResourcesWithProperty(RDF.type, ACL.Authorization);
        try
        {
            while (it.hasNext())
            {
                Resource authorization = it.next();
                
                graphUri = getAuthRequestContainerUriBuilder().path(UUID.randomUUID().toString() + "/").build(); // URI of the new access request graph
                Model requestModel = ModelFactory.createDefaultModel();
                
                Resource agent = authorization.getPropertyResourceValue(ACL.agent);
                if (!agent.equals(getAgentContext().get().getAgent())) throw new IllegalStateException("Agent requesting access must be authenticated");

                String humanReadableName = getAgentsHumanReadableName(getAgentContext().get().getAgent());
                String accessRequestLabel = humanReadableName != null ? "Access request by " + humanReadableName : null; // TO-DO: localize the string
                        
                Resource agentGroup = authorization.getPropertyResourceValue(ACL.agentGroup);
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
                
                if (agentGroup != null) accessRequest.addProperty(LACL.requestAgentGroup, agentGroup);
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
                getApplication().getAdminApplication().getService().getGraphStoreClient().add(graphUri.toString(), requestModel);
            }
           
            return Response.ok().build();
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
    
    public EndUserApplication getApplication()
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
    
}
