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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.core.MediaType;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.model.TemplateCall;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.mail.Address;
import javax.mail.MessagingException;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.servlet.ServletConfig;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.ClientErrorException;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles requests for access.
 * Creates an authorization request and sends a notification email to the maker of the application.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RequestAccess extends ResourceBase
{
    
    private static final Logger log = LoggerFactory.getLogger(RequestAccess.class);
    
    private final Address notificationAddress;
    private final String emailSubject;
    private final String emailText;
    private final UriBuilder authRequestContainerUriBuilder;
    private final Query agentQuery;

    @Inject
    public RequestAccess(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
                  Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
                  Ontology ontology, Optional<TemplateCall> templateCall,
                  @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
                  @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
                  @Context DataManager dataManager, @Context Providers providers,
                  com.atomgraph.linkeddatahub.Application system, @Context final ServletConfig servletConfig)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application,
                ontology, templateCall,
                httpHeaders, resourceContext,
                httpServletRequest, securityContext,
                dataManager, providers,
                system);
        agentQuery = system.getAgentQuery();
        
        // TO-DO: extract AuthorizationRequest container URI from ontology Restrictions
        authRequestContainerUriBuilder = uriInfo.getBaseUriBuilder().path(com.atomgraph.linkeddatahub.Application.AUTHORIZATION_REQUEST_PATH);
        
        try
        {
            String notificationAddressParam = servletConfig.getServletContext().getInitParameter(APLC.notificationAddress.getURI());
            if (notificationAddressParam == null) throw new WebApplicationException(new ConfigurationException(APLC.notificationAddress));
            InternetAddress[] notificationAddresses = InternetAddress.parse(notificationAddressParam);
            // if (notificationAddresses.size() == 0) throw Exception...
            notificationAddress = notificationAddresses[0];
        }
        catch (AddressException ex)
        {
            throw new WebApplicationException(ex);
        }
        
        emailSubject = servletConfig.getServletContext().getInitParameter(APLC.requestAccessEMailSubject.getURI());
        if (emailSubject == null) throw new WebApplicationException(new ConfigurationException(APLC.requestAccessEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(APLC.requestAccessEMailText.getURI());
        if (emailText == null) throw new WebApplicationException(new ConfigurationException(APLC.requestAccessEMailText));
    }
    
    @Override
    public Response construct(InfModel infModel)
    {
        if (!getTemplateCall().get().hasArgument(APLT.forClass)) throw new BadRequestException("aplt:forClass argument is mandatory for aplt:RequestAccess template");

        Resource forClass = getTemplateCall().get().getArgumentProperty(APLT.forClass).getResource();
        ResIterator it = infModel.getRawModel().listResourcesWithProperty(RDF.type, forClass);
        try
        {
            Agent agent = (Agent)getSecurityContext().getUserPrincipal();
            Resource accessRequest = it.next();
            Resource requestAgent = accessRequest.getPropertyResourceValue(LACL.requestAgent);
            if (!requestAgent.equals(agent)) throw new IllegalStateException("Agent requesting access must be authenticated");
            
            Resource owner = getApplication().getMaker();
            if (owner == null) throw new IllegalStateException("Application <" + getApplication().getURI() + "> does not have a maker (foaf:maker)");
            String ownerURI = owner.getURI();
                    
            ParameterizedSparqlString pss = new ParameterizedSparqlString(getAgentQuery().toString());
            pss.setParam(FOAF.Agent.getLocalName(), owner);
            // query agent data with SPARQL because the public laclt:AgentItem description does not expose foaf:mbox (which we need below in order to send an email)
            Model agentModel = getAgentService().getSPARQLClient().loadModel(pss.asQuery());
            owner = agentModel.getResource(ownerURI);
            if (!agentModel.containsResource(owner)) throw new IllegalStateException("Could not load agent's <" + ownerURI + "> description from admin service");

            URI authRequestContainerURI = getAuthRequestContainerUriBuilder().queryParam(APLT.forClass.getLocalName(), forClass.getURI()).build();
            try (Response cr1 = getDataManager().getEndpoint(authRequestContainerURI).
                    request(getMediaTypes().getReadable(Model.class).toArray(new javax.ws.rs.core.MediaType[0])).
                    post(Entity.entity(infModel.getRawModel(), MediaType.APPLICATION_NTRIPLES_TYPE)))
            {
                if (!cr1.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("POST request to AuthorizationRequest container: {} unsuccessful. Reason: {}", cr1.getLocation(), cr1.getStatusInfo().getReasonPhrase());
                    // throw new ClientErrorException(cr1); // this gives "java.lang.IllegalStateException: Entity input stream has already been closed."
                    throw new ClientErrorException("POST request to AuthorizationRequest container unsuccesful", cr1.getStatusInfo().getStatusCode());
                }

                try
                {
                    sendEmail(owner, accessRequest);
                }
                catch (MessagingException | UnsupportedEncodingException ex)
                {
                    if (log.isErrorEnabled()) log.error("Could not send Context creation email to Agent: {}", agent.getURI());
                }

                return get();
            }
        }
        finally
        {
            it.close();
        }
    }
    
    public void sendEmail(Resource owner, Resource accessRequest) throws MessagingException, UnsupportedEncodingException
    {
        // TO-DO: trim values
        String givenName = owner.getRequiredProperty(com.atomgraph.linkeddatahub.vocabulary.FOAF.givenName).getString();
        String familyName = owner.getRequiredProperty(com.atomgraph.linkeddatahub.vocabulary.FOAF.familyName).getString();
        String fullName = givenName + " " + familyName;
        // we expect foaf:mbox value as mailto: URI (it gets converted from literal in Model provider)
        String mbox = owner.getRequiredProperty(com.atomgraph.linkeddatahub.vocabulary.FOAF.mbox).getResource().getURI().substring("mailto:".length());

        Resource requestAgent = accessRequest.getPropertyResourceValue(LACL.requestAgent);
        Resource accessTo = accessRequest.getPropertyResourceValue(LACL.requestAccessTo);

        EMailListener.submit(getSystem().getMessageBuilder().
            subject(String.format(getEmailSubject(),
                getApplication().getProperty(DCTerms.title).getString())).
            from(getNotificationAddress()).
            to(mbox, fullName).
            textBodyPart(String.format(getEmailText(), requestAgent.getURI(), accessTo.getURI(), accessRequest.getURI())).
            build());
    }
    
    protected Service getAgentService()
    {
        return getApplication().canAs(EndUserApplication.class) ?
            getApplication().as(EndUserApplication.class).getAdminApplication().getService() :
            getApplication().getService();
    }
    
    private Address getNotificationAddress()
    {
        return notificationAddress;
    }
    
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    public String getEmailText()
    {
        return emailText;
    }
    
    public UriBuilder getAuthRequestContainerUriBuilder()
    {
        return authRequestContainerUriBuilder;
    }
    
    public Query getAgentQuery()
    {
        return agentQuery;
    }
    
}