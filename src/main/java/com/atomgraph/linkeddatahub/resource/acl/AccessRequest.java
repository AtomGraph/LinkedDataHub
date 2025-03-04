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
import com.atomgraph.core.exception.ConfigurationException;
import static com.atomgraph.linkeddatahub.apps.model.AdminApplication.AUTHORIZATION_REQUEST_PATH;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.resource.admin.RequestAccess;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
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
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import java.net.URI;
import java.util.GregorianCalendar;
import java.util.Optional;
import java.util.UUID;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AccessRequest extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(RequestAccess.class);
    
    private final String emailSubject;
    private final String emailText;
    private final UriBuilder authRequestContainerUriBuilder;
    
    @Inject
    public AccessRequest(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        if (securityContext == null || !(securityContext.getUserPrincipal() instanceof Agent)) throw new IllegalStateException("Agent is not authenticated");

        Resource adminBaseUri = application.canAs(EndUserApplication.class) ?
                    application.as(EndUserApplication.class).getAdminApplication().getBase() :
                    application.getBase();
        authRequestContainerUriBuilder = UriBuilder.fromUri(URI.create(adminBaseUri.toString())).path(AUTHORIZATION_REQUEST_PATH);
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailText));

    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        throw new NotAllowedException("GET is not allowed on this endpoint");
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        graphUri = getAuthRequestContainerUriBuilder().path(UUID.randomUUID().toString() + "/").build(); // URI of the new access request graph
        Model requestModel = ModelFactory.createDefaultModel();
        ResIterator it = model.listResourcesWithProperty(RDF.type, ACL.Authorization);
        try
        {
            while (it.hasNext())
            {
                Resource authorization = it.next();
                
                Resource accessMode = authorization.getPropertyResourceValue(ACL.mode);
                // the RDF/POST encoding in the access request form can produce authorizations without modes (when none a checked) - ignore those
                if (accessMode == null) continue;
                
                Resource agent = authorization.getPropertyResourceValue(ACL.agent);
                Resource agentGroup = authorization.getPropertyResourceValue(ACL.agentGroup);
                Resource accessTo = authorization.getPropertyResourceValue(ACL.accessTo);
                Resource accessToClass = authorization.getPropertyResourceValue(ACL.accessToClass);
                
                Resource accessRequest = requestModel.createResource().
                    addProperty(RDF.type, LACL.AuthorizationRequest).
                    addProperty(LACL.requestMode, accessMode).
                    addLiteral(DCTerms.created, GregorianCalendar.getInstance());
                if (agent != null) accessRequest.addProperty(LACL.requestAgent, agent);
                if (agentGroup != null) accessRequest.addProperty(LACL.requestAgentGroup, agentGroup);
                if (accessTo != null) accessRequest.addProperty(LACL.requestAccessTo, accessTo);
                if (accessToClass != null) accessRequest.addProperty(LACL.requestAccessToClass, accessToClass);
                
                //if (!agent.equals(getAgentContext().get().getAgent())) throw new IllegalStateException("Agent requesting access must be authenticated");

//                Resource owner = getApplication().getMaker();
//                if (owner == null) throw new IllegalStateException("Application <" + getApplication().getURI() + "> does not have a maker (foaf:maker)");
//                String ownerURI = owner.getURI();

//                LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
//                    delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
//                Model agentModel = ldc.getModel(ownerURI);
//                owner = agentModel.getResource(ownerURI);
//                if (!agentModel.containsResource(owner)) throw new IllegalStateException("Could not load agent's <" + ownerURI + "> description from admin service");

    //            try
    //            {
    //                sendEmail(owner, accessRequest);
    //            }
    //            catch (MessagingException | UnsupportedEncodingException ex)
    //            {
    //                if (log.isErrorEnabled()) log.error("Could not send access request email to Agent: {}", getAgentContext().get().getAgent().getURI());
    //            }
            }
            
           return super.post(requestModel, false, graphUri); // don't wrap into try-with-resources because that will close the Response
        }
        finally
        {
            it.close();
        }
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
    
}
