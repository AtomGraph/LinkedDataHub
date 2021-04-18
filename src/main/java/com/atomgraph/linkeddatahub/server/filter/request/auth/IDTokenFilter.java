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
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.exceptions.TokenExpiredException;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.IOException;
import java.net.URI;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.concurrent.TimeUnit;
import javax.annotation.PostConstruct;
import javax.annotation.Priority;
import javax.json.JsonObject;
import javax.ws.rs.Priorities;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import org.apache.jena.ext.com.google.common.net.HttpHeaders;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Literal;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 10) // has to execute after WebIDFilter
public class IDTokenFilter extends AuthenticationFilter
{

    private static final Logger log = LoggerFactory.getLogger(IDTokenFilter.class);

    public static final String AUTH_SCHEME = "JWT";
    public static final String COOKIE_NAME = "LinkedDataHub.id_token";
    
    private ParameterizedSparqlString userAccountQuery;

    @PostConstruct
    public void init()
    {
        userAccountQuery = new ParameterizedSparqlString(getSystem().getUserAccountQuery().toString());
    }
    
    @Override
    public String getScheme()
    {
        return AUTH_SCHEME;
    }
    
    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (getApplication().isEmpty()) return; // skip filter if no application has matched
        if (request.getSecurityContext().getUserPrincipal() != null) return; // skip filter if agent already authorized

        // do not verify token for auth endpoints as that will lead to redirect loops
        if (request.getUriInfo().getAbsolutePath().equals(getLoginURL())) return;
        if (request.getUriInfo().getAbsolutePath().equals(getAuthorizeGoogleURL())) return;
        
        super.filter(request);
    }
    
    @Override
    public Resource authenticate(ContainerRequestContext request)
    {
        ParameterizedSparqlString pss = getUserAccountQuery();
        
        DecodedJWT idToken = getJWTToken(request);
        if (idToken == null) return null;

        if (!verify(idToken)) return null;
        
        String cacheKey = idToken.getIssuer() + idToken.getSubject();
        final Model agentModel;
        Literal userId = ResourceFactory.createStringLiteral(idToken.getSubject());
        if (getSystem().getOIDCModelCache().containsKey(cacheKey)) agentModel = getSystem().getOIDCModelCache().get(cacheKey);
        else
        {
            QuerySolutionMap qsm = new QuerySolutionMap();
            qsm.add(SIOC.ID.getLocalName(), userId);
            qsm.add(LACL.issuer.getLocalName(), ResourceFactory.createStringLiteral(idToken.getIssuer()));

            agentModel = loadModel(pss, qsm, getAgentService());
        }
        
        Resource account = getResourceByPropertyValue(agentModel, SIOC.ID, userId);
        if (account == null) return null; // UserAccount not found

        // we add token value to the UserAccount. This will allow SecurityContext to carry the token as well as DataManager to delegate it.
        Resource agent = account.getRequiredProperty(SIOC.ACCOUNT_OF).getResource();
        if (agent == null) throw new IllegalStateException("UserAccount is not attached to an agent (sioc:account_of property is missing)");
        
        // calculate ID token expiration in seconds and use it in the cache
        long expiration = ChronoUnit.SECONDS.between(Instant.now(), idToken.getExpiresAt().toInstant());
        getSystem().getOIDCModelCache().put(cacheKey, agentModel, expiration, TimeUnit.SECONDS);
        
        return agent;
    }
    
    protected DecodedJWT getJWTToken(ContainerRequestContext request)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequest cannot be null");

        Cookie jwtCookie = request.getCookies().get(COOKIE_NAME);
        if (jwtCookie != null) return JWT.decode(jwtCookie.getValue());

        return null;
    }
    
    protected boolean verify(DecodedJWT idToken)
    {
        Date now = new Date();
        if (idToken.getExpiresAt().before(now))
        {
            if (log.isDebugEnabled()) log.debug("ID token for subject '{}' has expired at {}", idToken.getSubject(), idToken.getExpiresAt());
            throw new TokenExpiredException("ID token for subject '"  + idToken.getSubject() + "' has expired at " + idToken.getExpiresAt());
        }
        
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
                    NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
            
            Response response = Response.seeOther(request.getUriInfo().getAbsolutePath()).
                // Jersey 1.x NewCookie does not support Expires, we need to write the header explicitly
                header(HttpHeaders.SET_COOKIE, deleteCookie.toString() + ";Expires=Thu, 01 Jan 1970 00:00:00 GMT").
                build();
            throw new WebApplicationException(response);
        }
    }

    public URI getLoginURL()
    {
        return getAdminApplication().getBaseURI().resolve("oauth2/login"); // TO-DO: extract from ontology Template
    }
    
    public URI getAuthorizeGoogleURL()
    {
        return getAdminApplication().getBaseURI().resolve("oauth2/authorize/google"); // TO-DO: extract from ontology Template
    }
    
    public AdminApplication getAdminApplication()
    {
        if (getApplication().get().canAs(EndUserApplication.class))
            return getApplication().get().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().get().as(AdminApplication.class);
    }
    
    public ParameterizedSparqlString getUserAccountQuery()
    {
        return userAccountQuery.copy();
    }
    
}
