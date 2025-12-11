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
package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import java.math.BigInteger;
import java.net.URI;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.UUID;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract base class for OAuth 2.0 authorization endpoints.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class AuthorizeBase
{
    private static final Logger log = LoggerFactory.getLogger(AuthorizeBase.class);

    /** JWT cookie name */
    public static final String COOKIE_NAME = "LinkedDataHub.state";
    /** URL parameter name */
    public static final String REFERER_PARAM_NAME = "referer";

    private final HttpServletRequest httpServletRequest;
    private final Application application;
    private final com.atomgraph.linkeddatahub.Application system;
    private final String clientID;

    /**
     * Constructs resource from current request info.
     *
     * @param httpServletRequest servlet request
     * @param application application
     * @param system JAX-RS application
     * @param clientID OAuth client ID
     */
    public AuthorizeBase(HttpServletRequest httpServletRequest, Application application, com.atomgraph.linkeddatahub.Application system, String clientID)
    {
        if (!application.canAs(EndUserApplication.class))
            throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");

        this.httpServletRequest = httpServletRequest;
        this.application = application;
        this.system = system;
        this.clientID = clientID;
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }

    /**
     * Implements the HTTP <code>GET</code> method.
     *
     * @param originUri URI to redirect back to
     * @return response object
     */
    @GET
    public Response get(@QueryParam(REFERER_PARAM_NAME) String originUri)
    {
        // the redirect URI must be on the domain, not sub-domains (i.e. on the root dataspace)
        URI redirectUri = UriBuilder.fromUri(getSystem().getBaseURI()).
            path(getLoginClass()).
            build();

        String state = new BigInteger(130, new SecureRandom()).toString(32);
        String stateValue = Base64.getEncoder().encodeToString((state + ";" + originUri).getBytes());
        // Cookie path is "/" to make it accessible across all dataspaces
        NewCookie stateCookie = new NewCookie.Builder(COOKIE_NAME).
            value(stateValue).
            path("/").
            build();

        UriBuilder authUriBuilder = getAuthorizeUriBuilder(getAuthorizeEndpoint(), getClientID(), redirectUri.toString(), getScope(), stateValue, UUID.randomUUID().toString());

        return Response.seeOther(authUriBuilder.build()).
            cookie(stateCookie).
            build();
    }

    /**
     * Returns the OAuth authorization endpoint URI.
     *
     * @return authorization endpoint URI
     */
    protected abstract URI getAuthorizeEndpoint();

    /**
     * Returns the OAuth scope string.
     *
     * @return scope string
     */
    protected abstract String getScope();

    /**
     * Returns the Login class for building the redirect URI.
     *
     * @return Login class
     */
    protected abstract Class<?> getLoginClass();

    /**
     * Builds a URI for the OAuth 2.0 / OpenID Connect authorization request.
     * Constructs the authorization endpoint URL with standard OAuth parameters.
     *
     * @param endpoint OAuth authorization endpoint URI
     * @param clientID OAuth client ID
     * @param redirectURI redirect URI for the authorization response
     * @param scope OAuth scope string
     * @param stateValue state parameter for CSRF protection
     * @param nonce nonce parameter for replay attack prevention
     * @return URI builder with authorization request parameters
     */
    public UriBuilder getAuthorizeUriBuilder(URI endpoint, String clientID, String redirectURI, String scope, String stateValue, String nonce)
    {
        return UriBuilder.fromUri(endpoint).
            queryParam("response_type", "code").
            queryParam("client_id", clientID).
            queryParam("redirect_uri", redirectURI).
            queryParam("scope", scope).
            queryParam("state", stateValue).
            queryParam("nonce", nonce);
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
     * Returns servlet request.
     *
     * @return servlet request
     */
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
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
     * Returns system application.
     *
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns OAuth client ID.
     *
     * @return client ID
     */
    protected String getClientID()
    {
        return clientID;
    }

}
