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

import com.atomgraph.linkeddatahub.model.UserAccount;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.net.URI;
import javax.ws.rs.NotAuthorizedException;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import org.apache.jena.ext.com.google.common.net.HttpHeaders;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDFS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
public class JWTFilter extends AuthFilter
{

    private static final Logger log = LoggerFactory.getLogger(JWTFilter.class);

    public static final String COOKIE_NAME = "id_token";
    
    @Override
    public String getScheme()
    {
        return "JWT";
    }
    
    @Override
    public boolean isApplied(Application application, String realm, ContainerRequestContext request)
    {
        return getJWTToken(request) != null;
    }
    
    @Override
    public QuerySolutionMap getQuerySolutionMap(String realm, ContainerRequestContext request, URI absolutePath, Resource accessMode)
    {
        DecodedJWT jwt = getJWTToken(request);
        if (jwt != null)
        {
            String userId = jwt.getSubject();
            QuerySolutionMap qsm = new QuerySolutionMap();
            RDFNode neverMatch = RDFS.Resource; // non-matching value that disables the unused branch of UNION
            qsm.add("this", ResourceFactory.createResource(absolutePath.toString()));
            qsm.add("Mode", accessMode);
            qsm.add(SIOC.ID.getLocalName(), ResourceFactory.createTypedLiteral(userId));
            qsm.add(SIOC.NAME.getLocalName(), neverMatch);

            return qsm;
        }
        
        return null;
    }
    
    @Override
    public ContainerRequestContext authenticate(String realm, ContainerRequestContext request, Resource accessMode, UserAccount account, Resource agent)
    {
        DecodedJWT jwt = getJWTToken(request);
        if (jwt != null)
        {
            String userId = jwt.getSubject();

            if (account != null)
            {
                account.addLiteral(LACL.jwtToken, jwt.getPayload()); // storing token during request - might need to forward authentication
                if (log.isDebugEnabled()) log.debug("Authenticated Agent: {} UserAccount: {}", agent, account);
                return request;
            }
            else
            {
                if (log.isTraceEnabled()) log.trace("UserAccount with ID '{}' not found", userId);
                throw new NotAuthorizedException("UserAccount with ID '" + userId + "' not found", realm);
            }
        }

        
        return request;
    }
    
    protected DecodedJWT getJWTToken(ContainerRequestContext request)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequest cannot be null");

        String authHeader = request.getHeaderString(HttpHeaders.AUTHORIZATION);
        
        if (authHeader != null && authHeader.startsWith("Bearer "))
        {
            String idToken = authHeader.substring("Bearer ".length());
            return JWT.decode(idToken);
        }

        Cookie jwtCookie = request.getCookies().get("id_token");
        if (jwtCookie != null) return JWT.decode(jwtCookie.getValue());

        return null;
    }

    @Override
    public void login(Application app, String realm, ContainerRequestContext request)
    {
        URI location = app.getBaseURI().resolve("oauth2/authorize/google");
        Response response = Response.seeOther(location).build();
        throw new WebApplicationException(response);
    }

    @Override
    public void logout(Application app, String realm, ContainerRequestContext request)
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
    
}
