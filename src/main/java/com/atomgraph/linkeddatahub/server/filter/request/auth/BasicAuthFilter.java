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

import com.atomgraph.linkeddatahub.apps.model.Application;
import org.apache.jena.rdf.model.Literal;
import org.apache.jena.rdf.model.Resource;
import com.sun.jersey.api.container.MappableContainerException;
import com.sun.jersey.core.util.Base64;
import com.sun.jersey.spi.container.ContainerRequest;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;
import com.atomgraph.core.exception.AuthenticationException;
import com.atomgraph.linkeddatahub.model.UserAccount;
import com.atomgraph.processor.vocabulary.SIOC;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import java.net.URI;
import javax.ws.rs.core.SecurityContext;
import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDFS;

/**
 * HTTP basic authentication request filter.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class BasicAuthFilter extends AuthFilter
{
    private static final Logger log = LoggerFactory.getLogger(BasicAuthFilter.class);
    
    @Override
    public String getScheme()
    {
        return SecurityContext.BASIC_AUTH;
    }
    
    @Override
    public boolean isApplied(Application application, String realm, ContainerRequest request)
    {
        return getCredentials(realm, request) != null;
    }
    
    @Override
    public QuerySolutionMap getQuerySolutionMap(String realm, ContainerRequest request, URI absolutePath, Resource accessMode)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        RDFNode neverMatch = RDFS.Resource; // non-matching value that disables the unused branch of UNION
        qsm.add("this", ResourceFactory.createResource(absolutePath.toString()));
        qsm.add("Mode", accessMode);
        
        String[] credentials = getCredentials(realm, request);
        if (credentials != null)
        {
            String username = credentials[0];
            //String password = credentials[1];
            qsm.add(SIOC.NAME.getLocalName(), ResourceFactory.createTypedLiteral(username));
            qsm.add(SIOC.ID.getLocalName(), neverMatch);
            
            return qsm;
        }
            
        return null;
    }
    
    @Override
    public void login(Application application, String realm, ContainerRequest request)
    {
        //if (getCredentials(realm, request) == null) // otherwise we never get to authorization
        //{
            if (log.isDebugEnabled()) log.debug("Forced login on request URI: {}", request.getAbsolutePath());
            throw new AuthenticationException("Forced login", realm);
        //}
    }
    
    @Override
    public void logout(Application application, String realm, ContainerRequest request)
    {
        if (log.isDebugEnabled()) log.debug("Forced logout on request URI: {}", request.getAbsolutePath());
        throw new AuthenticationException("Logged out", realm);
    }
    
    @Override
    public ContainerRequest authenticate(String realm, ContainerRequest request, Resource accessMode, UserAccount account, Resource agent)
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequest cannot be null");
            
        String[] credentials = getCredentials(realm, request);
        if (credentials != null)
        {
            String username = credentials[0];
            String password = credentials[1];

            //if (account != null)
            //{
                if (passwordMatches(account, password))
                {
                    account.addLiteral(LACL.password, password); // storing password during request - might need to forward authentication
                    if (log.isDebugEnabled()) log.debug("Authenticated Agent: {} UserAccount: {}", agent, account);
                    return request;
                }
                else
                {
                    if (log.isDebugEnabled()) log.debug("Bad credentials for UserAccount '{}' on realm '{}'", account, realm);
                    throw new AuthenticationException("Bad credentials", realm);
                }
            /*
            }
            else
            {
                if (log.isTraceEnabled()) log.trace("UserAccount with username '{}' not found on realm '{}'", username, realm);
                throw new AuthenticationException("UserAccount with username '" + username + "' not found", realm);
            }
            */
        }
        
        return request;
    }
    
    protected String[] getCredentials(String realm, ContainerRequest request)
    {
        if (realm == null) throw new IllegalArgumentException("Realm cannot be null");        
        if (request == null) throw new IllegalArgumentException("ContainerRequest cannot be null");

        String authHeader = request.getHeaderValue(ContainerRequest.AUTHORIZATION);
        if (authHeader == null) return null;

        if (!authHeader.startsWith("Basic "))
        {
            if (log.isWarnEnabled()) log.warn("Only HTTP Basic authentication is supported");
            throw new WebApplicationException(Response.Status.BAD_REQUEST); // is there a better status code?
        }

        authHeader = authHeader.substring("Basic ".length());
        String[] values = Base64.base64Decode(authHeader).split(":", 2);
        if (values.length < 2)
        {
            if (log.isDebugEnabled()) log.debug("Invalid syntax for username and password");
            throw new MappableContainerException(
                new AuthenticationException("Invalid syntax for username and password", realm));
        }

        String username = values[0];
        String password = values[1];
        if (username.isEmpty() || password.isEmpty()) // (username == null || password == null)
        {
            if (log.isDebugEnabled()) log.debug("Missing username or password");
            throw new MappableContainerException(
                new AuthenticationException("Missing username or password", realm));
        }

        return values;
    }
    
    public boolean passwordMatches(UserAccount account, String password)
    {
        if (account == null) throw new IllegalArgumentException("UserAccount cannot be null");
        if (password == null) throw new IllegalArgumentException("Password cannot be null");
        
        Literal storedHash = account.getRequiredProperty(LACL.passwordHash).getLiteral();
        return BCrypt.checkpw(password, storedHash.getString());
    }
    
}