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
package com.atomgraph.linkeddatahub.resource.oauth2.google;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LACLT;
import com.atomgraph.processor.model.Template;
import com.atomgraph.processor.model.TemplateCall;
import java.math.BigInteger;
import java.net.URI;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Authorize extends ResourceBase
{
    private static final Logger log = LoggerFactory.getLogger(Authorize.class);
    
    public static final String ENDPOINT_URI = "https://accounts.google.com/o/oauth2/v2/auth";
    public static final String SCOPE = "openid email profile";
    public static final String COOKIE_NAME = "LinkedDataHub.state";

    private final String clientID;
    
    @Inject
    public Authorize(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
        
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        clientID = (String)system.getProperty(Google.clientID.getURI());
    }
    
    @Override
    public Response get()
    {
        if (getClientID() == null) throw new ConfigurationException(Google.clientID);
        
        final String originUri;
        if (getHttpHeaders().getHeaderString("Referer") != null) originUri = getHttpHeaders().getHeaderString("Referer");
        else originUri  = getEndUserBaseURI().toString();
        
        URI redirectUri = getUriInfo().getBaseUriBuilder().
            path(getOntology().getOntModel().getOntClass(LACLT.OAuth2Login.getURI()).
                as(Template.class).getMatch().toString()). // has to be a URI template without parameters
            build();

        String state = new BigInteger(130, new SecureRandom()).toString(32);
        String stateValue = Base64.getEncoder().encodeToString((state + ";" + originUri).getBytes());
        NewCookie stateCookie = new NewCookie(COOKIE_NAME, stateValue, getEndUserBaseURI().getPath(), null, NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
        
        UriBuilder authUriBuilder = UriBuilder.fromUri(ENDPOINT_URI).
            queryParam("response_type", "code").
            queryParam("client_id", getClientID()).
            queryParam("redirect_uri", redirectUri).
            queryParam("scope", SCOPE).
            queryParam("state", stateValue).
            queryParam("nonce", UUID.randomUUID().toString());
        
        return Response.seeOther(authUriBuilder.build()).
            cookie(stateCookie).
            build();
    }

    public URI getEndUserBaseURI()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().getBaseURI();
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication().getBaseURI();
    }
    
    private String getClientID()
    {
        return clientID;
    }
    
}
