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
import com.atomgraph.core.exception.ClientException;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfo;
import com.atomgraph.linkeddatahub.client.DataManager;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
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
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Entity;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import static javax.ws.rs.core.Response.Status.BAD_REQUEST;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
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

    @Inject
    public RequestAccess(@Context UriInfo uriInfo, @Context ClientUriInfo clientUriInfo, @Context Request request, @Context MediaTypes mediaTypes,
                  Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
                  Ontology ontology, Optional<TemplateCall> templateCall,
                  @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
                  Client client,
                  @Context SecurityContext securityContext,
                  @Context DataManager dataManager, @Context Providers providers,
                  @Context Application system, @Context final ServletConfig servletConfig)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application,
                ontology, templateCall,
                httpHeaders, resourceContext,
                client,
                securityContext,
                dataManager, providers,
                (com.atomgraph.linkeddatahub.Application)system);
        
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
        if (!getTemplateCall().get().hasArgument(APLT.forClass))
            throw new WebApplicationException(new IllegalStateException("aplt:forClass argument is mandatory for aplt:RequestAccess template"), BAD_REQUEST);

        Resource forClass = getTemplateCall().get().getArgumentProperty(APLT.forClass).getResource();
        ResIterator it = infModel.getRawModel().listResourcesWithProperty(RDF.type, forClass);
        try
        {
            Agent agent = (Agent)getSecurityContext().getUserPrincipal();
            Resource accessRequest = it.next();
            Resource requestAgent = accessRequest.getPropertyResourceValue(LACL.requestAgent);
            if (!requestAgent.equals(agent)) throw new IllegalStateException("Agent requesting access must be authenticated");
            
            Resource owner = getApplication().getMaker();
            if (owner == null) throw new IllegalStateException("Application '" + getApplication().getURI() + "' does not have a maker (foaf:maker)");

            Response cr = null;
            try
            {
                cr = getDataManager().getEndpoint(URI.create(owner.getURI())).
                        request(MediaType.TEXT_NQUADS_TYPE).
                        get(); // load maker's WebID model
                
                owner = cr.readEntity(Dataset.class).getDefaultModel().getResource(owner.getURI());
                
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("GET WebID profile: {} unsuccessful. Reason: {}", cr.getLocation(), cr.getStatusInfo().getReasonPhrase());
                    throw new ClientException(cr);
                }

                Response cr1 = null;
                try
                {
                    URI authRequestContainerURI = getAuthRequestContainerUriBuilder().queryParam(APLT.forClass.getLocalName(), forClass.getURI()).build();
                    cr1 = getDataManager().getEndpoint(authRequestContainerURI).
                        request(getMediaTypes().getReadable(Model.class).toArray(new javax.ws.rs.core.MediaType[0])).
                        post(Entity.entity(infModel.getRawModel(), MediaType.TEXT_NTRIPLES_TYPE));

                    if (!cr1.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("POST request to AuthorizationRequest container: {} unsuccessful. Reason: {}", cr1.getLocation(), cr1.getStatusInfo().getReasonPhrase());
                        throw new ClientException(cr1);
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
                finally
                {
                    if (cr1 != null) cr1.close();
                }
            }
            finally
            {
                if (cr != null) cr.close();
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
    
}
