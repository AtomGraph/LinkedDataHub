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
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
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

    private final UriInfo uriInfo;
    private final HttpServletRequest httpServletRequest;
    private final Application application;
    private final String clientID;

    /**
     * Constructs resource from current request info.
     *
     * @param uriInfo URI info
     * @param httpServletRequest servlet request
     * @param application application
     * @param clientID OAuth client ID
     */
    public AuthorizeBase(UriInfo uriInfo, HttpServletRequest httpServletRequest,
            Application application, String clientID)
    {
        if (!application.canAs(EndUserApplication.class))
            throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");
        this.uriInfo = uriInfo;
        this.httpServletRequest = httpServletRequest;
        this.application = application;
        this.clientID = clientID;
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }

    /**
     * Implements the HTTP <code>GET</code> method.
     *
     * @return response object
     */
    @GET
    public Response get()
    {
        final String originUri =  getUriInfo().getQueryParameters().containsKey(REFERER_PARAM_NAME) ? getUriInfo().getQueryParameters().getFirst(REFERER_PARAM_NAME) : getEndUserApplication().getBase().getURI();

        // the redirect URI must be on the domain, not sub-domains (i.e. on the root dataspace)
        URI redirectUri = UriBuilder.fromUri(getRootContextURI()).
            path(getLoginClass()).
            build();

        String state = new BigInteger(130, new SecureRandom()).toString(32);
        String stateValue = Base64.getEncoder().encodeToString((state + ";" + originUri).getBytes());
        // Cookie path is "/" to make it accessible across all dataspaces
        NewCookie stateCookie = new NewCookie(COOKIE_NAME, stateValue, "/", null, NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);

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
     * Returns the base URI of this LinkedDataHub instance.
     * It equals to the base URI of the root dataspace.
     *
     * @return root base URI
     */
    public URI getRootContextURI()
    {
        URI requestUri = URI.create(getHttpServletRequest().getRequestURL().toString());
        String host = requestUri.getHost();

        // Strip all subdomains to get root domain
        String rootDomain;
        String[] parts = host.split("\\.");

        if (host.equals("localhost") || host.endsWith(".localhost"))
        {
            // Special case: localhost domains
            rootDomain = "localhost";
        }
        else if (parts.length >= 2)
        {
            // Regular domains: take last 2 parts (e.g., example.com)
            rootDomain = parts[parts.length - 2] + "." + parts[parts.length - 1];
        }
        else rootDomain = host;

        // Rebuild URI with root domain
        String scheme = requestUri.getScheme();
        int port = requestUri.getPort();
        String contextPath = getHttpServletRequest().getContextPath();

        if (port == -1)  return URI.create(scheme + "://" + rootDomain + contextPath + "/");
        else return URI.create(scheme + "://" + rootDomain + ":" + port + contextPath + "/");
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
     * Returns OAuth client ID.
     *
     * @return client ID
     */
    protected String getClientID()
    {
        return clientID;
    }

}
