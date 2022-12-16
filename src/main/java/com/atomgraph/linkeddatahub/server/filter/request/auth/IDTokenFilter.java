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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.server.filter.request.AuthenticationFilter;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import static com.atomgraph.linkeddatahub.resource.admin.oauth2.Login.TOKEN_ENDPOINT;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.exceptions.TokenExpiredException;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.IOException;
import java.net.URI;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;
import javax.annotation.PostConstruct;
import javax.annotation.Priority;
import jakarta.json.JsonObject;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.MediaType;
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
 * Authentication filter that matches OIDC JWT tokens against application's user accounts.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 10) // has to execute after WebIDFilter
public class IDTokenFilter extends AuthenticationFilter
{

    private static final Logger log = LoggerFactory.getLogger(IDTokenFilter.class);

    /** ID of the JWT authentication scheme */
    public static final String AUTH_SCHEME = "JWT";
    /** White-list of OIDC issuers */
    public static final List<String> ISSUERS = Arrays.asList("https://accounts.google.com");
    /** Name of the cookie that stores the ID token */
    public static final String COOKIE_NAME = "LinkedDataHub.id_token";
    private String clientID, clientSecret;
    
    private ParameterizedSparqlString userAccountQuery;

    /**
     * Post-construct initialization of resources.
     */
    @PostConstruct
    public void init()
    {
        userAccountQuery = new ParameterizedSparqlString(getSystem().getUserAccountQuery().toString());
        clientID = (String)getSystem().getProperty(Google.clientID.getURI());
        clientSecret = (String)getSystem().getProperty(Google.clientSecret.getURI());
    }
    
    @Override
    public String getScheme()
    {
        return AUTH_SCHEME;
    }
    
    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request.getSecurityContext().getUserPrincipal() != null) return; // skip filter if agent already authorized
        if (!getApplication().canAs(EndUserApplication.class) && !getApplication().canAs(AdminApplication.class)) return; // skip "primitive" apps

        // do not verify token for auth endpoints as that will lead to redirect loops
        if (request.getUriInfo().getAbsolutePath().equals(getLoginURL())) return;
        if (request.getUriInfo().getAbsolutePath().equals(getAuthorizeGoogleURL())) return;
        
        super.filter(request);
    }
    
    @Override
    public SecurityContext authenticate(ContainerRequestContext request)
    {
        ParameterizedSparqlString pss = getUserAccountQuery();
        
        String jwtString = getJWTToken(request);
        if (jwtString == null) return null;
        
        DecodedJWT jwt = JWT.decode(jwtString);
        if (!jwt.getAudience().contains(getClientID()) || !ISSUERS.contains(jwt.getIssuer())) return null; // in Google's JWT tokens, "aud" is the client ID
        
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
                throw new TokenExpiredException("ID token for subject '"  + jwt.getSubject() + "' has expired at " + jwt.getExpiresAt());
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
    
    /**
     * Verifies the validity of the specified JWT ID token.
     * 
     * @param idToken ID token
     * @return true if valid
     */
    protected boolean verify(DecodedJWT idToken)
    {
        // TO-DO: use keys, this is for debugging purposes only: https://developers.google.com/identity/protocols/oauth2/openid-connect#validatinganidtoken
        try (Response cr = getSystem().getNoCertClient().
            target("https://oauth2.googleapis.com/tokeninfo").
            queryParam("id_token", idToken.getToken()).
            request(MediaType.APPLICATION_JSON_TYPE).
            get())
        {
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isDebugEnabled()) log.debug("Could not verify JWT token for subject '{}'", idToken.getSubject());
//                throw new JWTVerificationException("Could not verify JWT token for subject '"  + idToken.getSubject() + "'");
                return false;
            }
                
            JsonObject verifiedIdToken = cr.readEntity(JsonObject.class);
            if (idToken.getIssuer().equals(verifiedIdToken.getString("iss")) &&
                idToken.getSubject().equals(verifiedIdToken.getString("sub")) &&
                idToken.getKeyId().equals(verifiedIdToken.getString("kid")))
                return true;
        }

//        throw new JWTVerificationException("Could not verify JWT token for subject '"  + idToken.getSubject() + "'");
        return false;
    }
    
    @Override
    public void login(Application app, ContainerRequestContext request)
    {
        Response response = Response.seeOther(getAuthorizeGoogleURL()).build();
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
            NewCookie deleteCookie = new NewCookie(cookie.getName(), null,
                app.getBase().getURI(), null,
                    NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, new Date(0), true, true);
            
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
        
        try (Response cr = getSystem().getClient().target(TOKEN_ENDPOINT).
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
     * Returns the URL of the OAuth login endpoint.
     * 
     * @return endpoint URI
     * @see com.atomgraph.linkeddatahub.resource.admin.oauth2.Login
     */
    public URI getLoginURL()
    {
        return getAdminApplication().getBaseURI().resolve("oauth2/login"); // TO-DO: extract from Login class
    }
    
    /**
     * Returns the URL of the Google authorization endpoint.
     * 
     * @return endpoint URI
     * @see com.atomgraph.linkeddatahub.resource.admin.oauth2.google.Authorize
     */
    public URI getAuthorizeGoogleURL()
    {
        return getAdminApplication().getBaseURI().resolve("oauth2/authorize/google"); // TO-DO: extract from ontology Template
    }
    
    /**
     * Returns the admin application of the current dataspace.
     * 
     * @return admin application resource
     */
    public AdminApplication getAdminApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().as(AdminApplication.class);
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
     * Returns the configured Google client ID for this application.
     * 
     * @return client ID
     */
    private String getClientID()
    {
        return clientID;
    }
    
    /**
     * Returns the configured Google client secret for this application.
     * 
     * @return client secret
     */
    private String getClientSecret()
    {
        return clientSecret;
    }
    
}
