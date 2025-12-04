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
package com.atomgraph.linkeddatahub.resource.admin.oauth2.orcid;

import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.ORCID;
import java.math.BigInteger;
import java.net.URI;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles ORCID authorization requests.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("oauth2/authorize/orcid")
public class Authorize
{
    private static final Logger log = LoggerFactory.getLogger(Authorize.class);

    /** ORCID's OAuth sandbox endpoint URL */
    public static final String ENDPOINT_URI = "https://sandbox.orcid.org/oauth/authorize";
    /** OAuth authorization scope - using /read-limited to allow email fetching */
    public static final String SCOPE = "/read-limited";
    /** State cookie name */
    public static final String COOKIE_NAME = "LinkedDataHub.orcid.state";
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
        clientID = (String)system.getProperty(ORCID.clientID.getURI());
    }

    /**
     * Implements the HTTP <code>GET</code> method.
     *
     * @return response object
     */
    @GET
    public Response get()
    {
        if (getClientID() == null) throw new ConfigurationException(ORCID.clientID);

        final String originUri;
        if (getUriInfo().getQueryParameters().containsKey(REFERER_PARAM_NAME)) originUri = getUriInfo().getQueryParameters().getFirst(REFERER_PARAM_NAME);
        else originUri = getEndUserApplication().getBase().getURI();

        URI redirectUri = getUriInfo().getBaseUriBuilder().
            path(Login.class).
            build();

        String state = new BigInteger(130, new SecureRandom()).toString(32);
        String stateValue = Base64.getEncoder().encodeToString((state + ";" + originUri).getBytes());
        NewCookie stateCookie = new NewCookie(COOKIE_NAME, stateValue, getEndUserApplication().getBaseURI().getPath(), null, NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);

        UriBuilder authUriBuilder = UriBuilder.fromUri(ENDPOINT_URI).
            queryParam("client_id", getClientID()).
            queryParam("response_type", "code").
            queryParam("scope", SCOPE).
            queryParam("redirect_uri", redirectUri).
            queryParam("state", stateValue);

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
     * Returns ORCID OAuth client ID.
     *
     * @return client ID
     */
    private String getClientID()
    {
        return clientID;
    }

}
