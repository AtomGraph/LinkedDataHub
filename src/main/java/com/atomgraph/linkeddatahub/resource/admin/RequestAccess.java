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
package com.atomgraph.linkeddatahub.resource.admin;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import static com.atomgraph.linkeddatahub.apps.model.AdminApplication.AUTHORIZATION_REQUEST_PATH;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.util.GregorianCalendar;
import java.util.Optional;
import java.util.UUID;
import jakarta.inject.Inject;
import jakarta.mail.MessagingException;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint that handles requests for access.
 * Creates an authorization request and sends a notification email to the maker of the application.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public class RequestAccess extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(RequestAccess.class);
    
    private final String emailSubject;
    private final String emailText;
    private final UriBuilder authRequestContainerUriBuilder;

    /**
     * Constructs access request resource.
     * 
     * @param request current request
     * @param uriInfo request URI information
     * @param mediaTypes registry of readable/writable media types
     * @param application current application
     * @param ontology current application's ontology
     * @param service current application's service
     * @param securityContext JAX-RS security service
     * @param providers registry of JAX-RS providers
     * @param system system application
     * @param servletConfig servlet config
     * @param agentContext optional agent context
     */
    @Inject
    public RequestAccess(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        if (securityContext == null || !(securityContext.getUserPrincipal() instanceof Agent)) throw new IllegalStateException("Agent is not authenticated");

        authRequestContainerUriBuilder = uriInfo.getBaseUriBuilder().path(AUTHORIZATION_REQUEST_PATH);
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(LDHC.requestAccessEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.requestAccessEMailText));
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        return super.get(false, getURI());
    }
    
    @POST
    @Override
    public Response post(Model requestModel, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        graphUri = getAuthRequestContainerUriBuilder().path(UUID.randomUUID().toString() + "/").build();
        new Skolemizer(graphUri.toString()).apply(requestModel);

        ResIterator it = requestModel.listResourcesWithProperty(RDF.type, LACL.AuthorizationRequest);
        try
        {
            Resource accessRequest = it.next();
            Resource requestAgent = accessRequest.getPropertyResourceValue(LACL.requestAgent);
            if (!requestAgent.equals(getAgentContext().get().getAgent())) throw new IllegalStateException("Agent requesting access must be authenticated");
            
            Resource owner = getApplication().getMaker();
            if (owner == null) throw new IllegalStateException("Application <" + getApplication().getURI() + "> does not have a maker (foaf:maker)");
            String ownerURI = owner.getURI();
            
            accessRequest.addLiteral(DCTerms.created, GregorianCalendar.getInstance());

            LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
            Model agentModel = ldc.getModel(ownerURI);
            owner = agentModel.getResource(ownerURI);
            if (!agentModel.containsResource(owner)) throw new IllegalStateException("Could not load agent's <" + ownerURI + "> description from admin service");

            Response response = super.post(requestModel, false, graphUri); // don't wrap into try-with-resources because that will close the Response

            try
            {
                sendEmail(owner, accessRequest);
            }
            catch (MessagingException | UnsupportedEncodingException ex)
            {
                if (log.isErrorEnabled()) log.error("Could not send access request email to Agent: {}", getAgentContext().get().getAgent().getURI());
            }

            return response; // 201 Created
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Sends access request notification email to applications owner.
     * 
     * @param owner application's owner
     * @param accessRequest access request resource
     * @throws MessagingException error sending email
     * @throws UnsupportedEncodingException encoding error
     */
    public void sendEmail(Resource owner, Resource accessRequest) throws MessagingException, UnsupportedEncodingException
    {
        // TO-DO: trim values?
        final String name;
        if (owner.hasProperty(FOAF.givenName) && owner.hasProperty(FOAF.familyName))
        {
            String givenName = owner.getProperty(FOAF.givenName).getString();
            String familyName = owner.getProperty(FOAF.familyName).getString();
            name = givenName + " " + familyName;
        }
        else
        {
            if (owner.hasProperty(FOAF.name)) name = owner.getProperty(FOAF.name).getString();
            else throw new IllegalStateException("Owner Agent '" + owner + "' does not have either foaf:givenName/foaf:familyName or foaf:name");
        }
        
        // we expect foaf:mbox value as mailto: URI (it gets converted from literal in Model provider)
        String mbox = owner.getRequiredProperty(FOAF.mbox).getResource().getURI().substring("mailto:".length());

        Resource requestAgent = accessRequest.getPropertyResourceValue(LACL.requestAgent);
        Resource accessTo = accessRequest.getPropertyResourceValue(LACL.requestAccessTo);

        MessageBuilder builder = getSystem().getMessageBuilder().
            subject(String.format(getEmailSubject(),
                getApplication().getProperty(DCTerms.title).getString())).
            to(mbox, name).
            textBodyPart(String.format(getEmailText(), requestAgent.getURI(), accessTo.getURI(), accessRequest.getURI()));
        
        if (getSystem().getNotificationAddress() != null) builder = builder.from(getSystem().getNotificationAddress());

        EMailListener.submit(builder.build());
    }
    
    /**
     * Returns the SPARQL service from which agent data is retrieved.
     * 
     * @return SPARQL service
     */
    protected Service getAgentService()
    {
        return getApplication().getService();
    }
    
    /**
     * Returns URI of this resource.
     * 
     * @return resource URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }
   
    /**
     * Returns the subject of the notification email.
     * 
     * @return subject
     */
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    /**
     * Returns the text of the notification email.
     * 
     * @return text
     */
    public String getEmailText()
    {
        return emailText;
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