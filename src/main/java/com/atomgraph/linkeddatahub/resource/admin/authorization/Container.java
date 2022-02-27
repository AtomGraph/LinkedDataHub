/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.admin.authorization;

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.inject.Inject;
import javax.mail.MessagingException;
import javax.servlet.ServletConfig;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Authorization container
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Container extends GraphStoreImpl
{
    private static final Logger log = LoggerFactory.getLogger(Container.class);
    
    private final String emailSubject;
    private final String emailText;

    @Inject
    public Container(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.authorizationEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.authorizationEMailSubject));
        
        emailText = servletConfig.getServletContext().getInitParameter(LDHC.authorizationEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.authorizationEMailText));

    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (getApplication().canAs(AdminApplication.class))
            try
            {
                sendEmail(getApplication().getMaker(), model);
            }
            catch (MessagingException | UnsupportedEncodingException ex)
            {
                if (log.isErrorEnabled()) log.error("Could not send authorization email");
            }

        return super.post(model, defaultGraph, graphUri);
    }

    @PUT
    @Override
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (getApplication().canAs(AdminApplication.class))
            try
            {
                sendEmail(getApplication().getMaker(), model);
            }
            catch (MessagingException | UnsupportedEncodingException ex)
            {
                if (log.isErrorEnabled()) log.error("Could not send authorization email");
            }
        
        return super.put(model, defaultGraph, graphUri);
    }

    public void sendEmail(Resource owner, Model authorizations) throws MessagingException, UnsupportedEncodingException
    {
        ResIterator it = authorizations.listResourcesWithProperty(RDF.type, ACL.Authorization);
        try
        {
            Resource auth = it.next();
            if (auth.hasProperty(ACL.agent))
            {
                Resource agent = auth.getPropertyResourceValue(ACL.agent);

                LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient().target(owner.getURI()), getSystem().getMediaTypes());
                Model agentModel = ldc.get();
                agent = agentModel.getResource(agent.getURI());
                if (!agentModel.containsResource(owner)) throw new IllegalStateException("Could not load agent's <" + agent.getURI() + "> description");

                final String name;
                if (agent.hasProperty(FOAF.givenName) && agent.hasProperty(FOAF.familyName))
                {
                    String givenName = agent.getProperty(FOAF.givenName).getString();
                    String familyName = agent.getProperty(FOAF.familyName).getString();
                    name = givenName + " " + familyName;
                }
                else
                {
                    if (agent.hasProperty(FOAF.name)) name = agent.getProperty(FOAF.name).getString();
                    else throw new IllegalStateException("Agent '" + agent + "' does not have either foaf:givenName/foaf:familyName or foaf:name");
                }

                // we expect foaf:mbox value as mailto: URI (it gets converted from literal in Model provider)
                String mbox = agent.getRequiredProperty(FOAF.mbox).getResource().getURI().substring("mailto:".length());
                String accessToList = auth.listProperties(ACL.accessTo).toList().stream().map(stmt -> stmt.getResource().getURI()).collect(Collectors.joining("\n"));
                String accessToClassList = auth.listProperties(ACL.accessToClass).toList().stream().map(stmt -> stmt.getResource().getURI()).collect(Collectors.joining("\n"));

                MessageBuilder builder = getSystem().getMessageBuilder().
                    subject(String.format(getEmailSubject(),
                        getApplication().getProperty(DCTerms.title).getString())).
                    to(mbox, name).
                    textBodyPart(String.format(getEmailText(), owner.getURI(), accessToList, accessToClassList));

                if (getSystem().getNotificationAddress() != null) builder = builder.from(getSystem().getNotificationAddress());

                EMailListener.submit(builder.build());
            }
        }
        finally
        {
            it.close();
        }
    }
    
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    public String getEmailText()
    {
        return emailText;
    }
    
}