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
package com.atomgraph.linkeddatahub.resource.admin.oauth2.google;

import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.resource.admin.oauth2.Login;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import java.math.BigInteger;
import java.net.URI;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles Google authorization requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("oauth2/authorize/google")
public class Authorize
{
    private static final Logger log = LoggerFactory.getLogger(Authorize.class);
    
    /** Google's OAuth endpoint URL */
    public static final String ENDPOINT_URI = "https://accounts.google.com/o/oauth2/v2/auth";
    /** OAuth authorization scope */
    public static final String SCOPE = "openid email profile";
    /** JWT cookie name */
    public static final String COOKIE_NAME = "LinkedDataHub.state";
    /** URL parameter name */
    public static final String REFERER_PARAM_NAME = "referer";

    private final UriInfo uriInfo;
    private final Application application;
    private final Ontology ontology;
    private final String clientID;
    
    /**
     * Constructs resource from current request info.
     * 
     * @param uriInfo URI info
     * @param application application
     * @param ontology application's ontology
     * @param service application's SPARQL service
     * @param system JAX-RS application
     */
    @Inject
    public Authorize(@Context UriInfo uriInfo, 
            Optional<Service> service, com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology,
                com.atomgraph.linkeddatahub.Application system)
    {
        this.uriInfo = uriInfo;
        this.application = application;
        this.ontology = ontology.get();
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        clientID = (String)system.getProperty(Google.clientID.getURI());
    }
    
    /**
     * Implements the HTTP <code>GET</code> method.
     * 
     * @return response object
     */
    @GET
    public Response get()
    {
        if (getClientID() == null) throw new ConfigurationException(Google.clientID);
        
        final String originUri;
        //if (getHttpHeaders().getHeaderString("Referer") != null) originUri = getHttpHeaders().getHeaderString("Referer"); // Referer value missing after redirect
        if (getUriInfo().getQueryParameters().containsKey(REFERER_PARAM_NAME)) originUri = getUriInfo().getQueryParameters().getFirst(REFERER_PARAM_NAME);
        else originUri = getEndUserApplication().getBase().getURI();
        
        URI redirectUri = getUriInfo().getBaseUriBuilder().
            path(Login.class).
            build();

        String state = new BigInteger(130, new SecureRandom()).toString(32);
        String stateValue = Base64.getEncoder().encodeToString((state + ";" + originUri).getBytes());
        NewCookie stateCookie = new NewCookie(COOKIE_NAME, stateValue, getEndUserApplication().getBaseURI().getPath(), null, NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
        
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

    /**
     * Returns the end-user application of the current dataspace.
     * 
     * @return application resource
     */
    public EndUserApplication getEndUserApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class);
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication();
    }
    
    /**
     * Returns URI information for the current request.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Returns matched application.
     * 
     * @return application resource
     */
    public Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns application's ontology.
     * 
     * @return ontology resource
     */
    public Ontology getOntology()
    {
        return ontology;
    }
    
    /**
     * Returns Google OAuth client ID.
     * 
     * @return client ID
     */
    private String getClientID()
    {
        return clientID;
    }
    
}
