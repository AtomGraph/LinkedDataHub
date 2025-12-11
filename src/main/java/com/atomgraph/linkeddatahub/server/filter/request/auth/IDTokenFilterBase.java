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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.filter.request.AuthenticationFilter;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.exceptions.TokenExpiredException;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.IOException;
import java.net.URI;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.Priority;
import jakarta.json.JsonObject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Literal;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract base class for OAuth 2.0 / OpenID Connect ID token authentication filters.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 10) // has to execute after WebIDFilter
public abstract class IDTokenFilterBase extends AuthenticationFilter
{
    private static final Logger log = LoggerFactory.getLogger(IDTokenFilterBase.class);

    /** ID of the JWT authentication scheme */
    public static final String AUTH_SCHEME = "JWT";
    /** Name of the cookie that stores the ID token */
    public static final String COOKIE_NAME = "LinkedDataHub.id_token";

    @Context HttpServletRequest httpServletRequest;

    private String clientID, clientSecret;
    private ParameterizedSparqlString userAccountQuery;

    /**
     * Post-construct initialization of resources.
     */
    @PostConstruct
    public void init()
    {
        userAccountQuery = new ParameterizedSparqlString(getSystem().getUserAccountQuery().toString());
        initClientCredentials();
    }

    /**
     * Initializes provider-specific client credentials.
     * Subclasses should load their OAuth client ID and secret here.
     */
    protected abstract void initClientCredentials();

    /**
     * Returns the list of trusted OIDC issuers for this provider.
     *
     * @return list of issuer URIs
     */
    protected abstract List<String> getIssuers();

    /**
     * Returns the JWKS endpoint URI for fetching public keys.
     *
     * @return JWKS endpoint URI
     */
    protected abstract URI getJWKSEndpoint();

    /**
     * Verifies the validity of the specified JWT ID token using JWKS-based signature verification.
     *
     * @param idToken ID token
     * @return true if valid
     * @see com.atomgraph.linkeddatahub.server.util.JWTVerifier#verify
     */
    protected boolean verify(DecodedJWT idToken)
    {
        return com.atomgraph.linkeddatahub.server.util.JWTVerifier.verify(
            idToken,
            getJWKSEndpoint(),
            getIssuers(),
            getClientID(),
            getSystem().getClient(),
            getSystem().getJWKSCache()
        );
    }

    /**
     * Returns the OAuth token endpoint URI for token refresh.
     *
     * @return token endpoint URI
     */
    protected abstract URI getTokenEndpoint();

    /**
     * Returns the URL of the OAuth login endpoint.
     *
     * @return endpoint URI
     */
    protected abstract URI getLoginURL();

    /**
     * Returns the URL of the OAuth authorization endpoint.
     *
     * @return endpoint URI
     */
    protected abstract URI getAuthorizeURL();

    @Override
    public String getScheme()
    {
        return AUTH_SCHEME;
    }

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request.getSecurityContext().getUserPrincipal() != null) return; // skip filter if agent already authorized
        if (!getApplication().isPresent()) return; // skip if no application matched
        if (!getApplication().get().canAs(EndUserApplication.class) && !getApplication().get().canAs(AdminApplication.class)) return; // skip "primitive" apps

        // do not verify token for auth endpoints as that will lead to redirect loops
        if (request.getUriInfo().getAbsolutePath().equals(getLoginURL())) return;
        if (request.getUriInfo().getAbsolutePath().equals(getAuthorizeURL())) return;

        super.filter(request);
    }

    @Override
    public SecurityContext authenticate(ContainerRequestContext request)
    {
        ParameterizedSparqlString pss = getUserAccountQuery();

        String jwtString = getJWTToken(request);
        if (jwtString == null) return null;

        DecodedJWT jwt = JWT.decode(jwtString);
        if (!jwt.getAudience().contains(getClientID()) || !getIssuers().contains(jwt.getIssuer())) return null;

        if (jwt.getExpiresAt().before(new Date()))
        {
            String refreshToken = getSystem().getRefreshToken(jwt.getSubject());
            if (refreshToken != null)
            {
                if (log.isDebugEnabled()) log.debug("ID token for subject '{}' has expired at {}, refreshing it", jwt.getSubject(), jwt.getExpiresAt());
                jwt = refreshIDToken(refreshToken);
            }
            else
            {
                if (log.isDebugEnabled()) log.debug("ID token for subject '{}' has expired at {}, refresh token not found", jwt.getSubject(), jwt.getExpiresAt());
                throw new TokenExpiredException("ID token for subject '%s' has expired at %s".formatted(jwt.getSubject(), jwt.getExpiresAt()));
            }
        }
        if (!verify(jwt)) return null;

        String cacheKey = jwt.getIssuer() + jwt.getSubject();
        final Model agentModel;
        Literal userId = ResourceFactory.createStringLiteral(jwt.getSubject());
        if (getSystem().getOIDCModelCache().containsKey(cacheKey)) agentModel = getSystem().getOIDCModelCache().get(cacheKey);
        else
        {
            QuerySolutionMap qsm = new QuerySolutionMap();
            qsm.add(SIOC.ID.getLocalName(), userId);
            qsm.add(LACL.issuer.getLocalName(), ResourceFactory.createStringLiteral(jwt.getIssuer()));

            agentModel = loadModel(pss, qsm, getAgentService());
        }

        Resource account = getResourceByPropertyValue(agentModel, SIOC.ID, userId);
        if (account == null) return null; // UserAccount not found

        // we add token value to the UserAccount. This will allow SecurityContext to carry the token as well as DataManager to delegate it.
        Resource agent = account.getRequiredProperty(SIOC.ACCOUNT_OF).getResource();
        if (agent == null) throw new IllegalStateException("UserAccount is not attached to an agent (sioc:account_of property is missing)");

        // calculate ID token expiration in seconds and use it in the cache
        long expiration = ChronoUnit.SECONDS.between(Instant.now(), jwt.getExpiresAt().toInstant());
        getSystem().getOIDCModelCache().put(cacheKey, agentModel, expiration, TimeUnit.SECONDS);

        // imitate type inference, otherwise we'll get Jena's polymorphism exception
        return new IDTokenSecurityContext(getScheme(), agent.addProperty(RDF.type, FOAF.Agent).as(Agent.class), jwtString);
    }

    /**
     * Retrieves JWT token from the request context.
     *
     * @param request request context
     * @return token content
     */
    protected String getJWTToken(ContainerRequestContext request)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequest cannot be null");

        Cookie jwtCookie = request.getCookies().get(COOKIE_NAME);
        if (jwtCookie != null) return jwtCookie.getValue();

        return null;
    }

    @Override
    public void login(Application app, ContainerRequestContext request)
    {
        Response response = Response.seeOther(getAuthorizeURL()).build();
        throw new WebApplicationException(response);
    }

    @Override
    public void logout(Application app, ContainerRequestContext request)
    {
        Cookie cookie = request.getCookies().get(COOKIE_NAME);
        if (cookie != null)
        {
            // Chrome does not seem to store permanent cookies (with Expires) from Domain=localhost
            // https://stackoverflow.com/questions/7346919/chrome-localhost-cookie-not-being-set
            NewCookie deleteCookie = new NewCookie.Builder(cookie.getName()).
                value(null).
                path(app.getBase().getURI()).
                expiry(new Date(0)).
                secure(true).
                httpOnly(true).
                build();

            Response response = Response.seeOther(request.getUriInfo().getAbsolutePath()).
                cookie(deleteCookie).
                build();
            throw new NotAuthorizedException(response);
        }
    }

    /**
     * Gets new ID token using a refresh token.
     *
     * @param refreshToken refresh token
     * @return ID token
     */
    public DecodedJWT refreshIDToken(String refreshToken)
    {
        Form form = new Form().
            param("grant_type", "refresh_token").
            param("client_id", getClientID()).
            param("client_secret", getClientSecret()).
            param("refresh_token", refreshToken);

        try (Response cr = getSystem().getClient().target(getTokenEndpoint()).
                request().post(Entity.form(form)))
        {
            JsonObject response = cr.readEntity(JsonObject.class);
            if (response.containsKey("error"))
            {
                if (log.isErrorEnabled()) log.error("OAuth error: '{}'", response.getString("error"));
                throw new InternalServerErrorException(response.getString("error"));
            }

            String idToken = response.getString("id_token");
            return JWT.decode(idToken);
        }
    }

    /**
     * Returns the admin application of the current dataspace.
     *
     * @return admin application resource
     */
    public AdminApplication getAdminApplication()
    {
        if (getApplication().get().canAs(EndUserApplication.class))
            return getApplication().get().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().get().as(AdminApplication.class);
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
     * @return root context URI
     */
    public URI getContextURI()
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

        if (port == -1)  return URI.create("%s://%s%s/".formatted(scheme, rootDomain, contextPath));
        else return URI.create("%s://%s:%d%s/".formatted(scheme, rootDomain, port, contextPath));
    }

    /**
     * Returns the user account lookup query.
     *
     * @return SPARQL string
     */
    public ParameterizedSparqlString getUserAccountQuery()
    {
        return userAccountQuery.copy();
    }

    /**
     * Returns the configured OAuth client ID for this application.
     *
     * @return client ID
     */
    protected String getClientID()
    {
        return clientID;
    }

    /**
     * Sets the OAuth client ID.
     *
     * @param clientID client ID
     */
    protected void setClientID(String clientID)
    {
        this.clientID = clientID;
    }

    /**
     * Returns the configured OAuth client secret for this application.
     *
     * @return client secret
     */
    protected String getClientSecret()
    {
        return clientSecret;
    }

    /**
     * Sets the OAuth client secret.
     *
     * @param clientSecret client secret
     */
    protected void setClientSecret(String clientSecret)
    {
        this.clientSecret = clientSecret;
    }

}
