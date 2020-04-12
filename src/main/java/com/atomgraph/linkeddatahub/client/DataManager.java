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
package com.atomgraph.linkeddatahub.client;

import org.apache.jena.util.LocationMapper;
import java.net.URI;
import javax.ws.rs.core.SecurityContext;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.filter.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.apps.model.Application;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.container.ResourceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manager for remote RDF dataset access.
 * Documents can be mapped to local copies.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DataManager extends com.atomgraph.client.util.DataManager
{
    private static final Logger log = LoggerFactory.getLogger(DataManager.class);
    
    private final Application application;
    private final SecurityContext securityContext;
    private final ResourceContext resourceContext;
    private final HttpServletRequest httpServletRequest;
    
    public DataManager(LocationMapper mapper, Client client, MediaTypes mediaTypes,
            boolean preemptiveAuth, boolean resolvingUncached,
            Application application,
            SecurityContext securityContext, ResourceContext resourceContext,
            HttpServletRequest httpServletRequest)
    {
        super(mapper, client, mediaTypes, preemptiveAuth, resolvingUncached);
        this.application = application;
        this.securityContext = securityContext;
        this.resourceContext = resourceContext;
        this.httpServletRequest = httpServletRequest;
    }
    
    @Override
    public boolean resolvingUncached(String filenameOrURI)
    {
        if (getApplication() != null && !isMapped(filenameOrURI))
        {
            // always resolve URIs relative to the root Context base URI
            boolean relative = !getRootContextURI().relativize(URI.create(filenameOrURI)).isAbsolute();
            return relative;
        }
        
        return false; // by default, do not resolve URIs
    }
    
    public ClientRequestFilter getClientAuthFilter(SecurityContext securityContext)
    {
        if (securityContext == null) throw new IllegalArgumentException("SecurityContext must be not null");

//        UserAccount userAccount = getUserAccount(securityContext);
//        if (userAccount != null) return getClientCertFilter(context, userAccount);

        if (securityContext.getUserPrincipal() instanceof Agent &&
                getSecurityContext().getAuthenticationScheme().equals(SecurityContext.CLIENT_CERT_AUTH))
            return new WebIDDelegationFilter((Agent)securityContext.getUserPrincipal());
        
        return null;
    }
    
    /*
    public ClientRequestFilter getClientCertFilter(Context context, UserAccount userAccount)
    {
        if (context == null) throw new IllegalArgumentException("Context must be not null");
        if (userAccount == null) throw new IllegalArgumentException("UserAccount must be not null");

        if (userAccount.hasProperty(LACL.password))
        {
            String username = userAccount.getProperty(SIOC.NAME).getString();
            String password = userAccount.getProperty(LACL.password).getString();

            return new HTTPBasicAuthFilter(username, password);
        }

        if (userAccount.hasProperty(LACL.jwtToken) && getApplication() != null)
        {
            String jwtToken = userAccount.getProperty(LACL.jwtToken).getString();
            return new JWTFilter(jwtToken, URI.create(getApplication().getBase(context).getURI()).getPath(), null); // getAppUriInfo().getBase().getHost()
        }

        throw new IllegalStateException("UserAccount does not have a lacl:password or sioc:id");
        
        return null;
    }
    */
    
    @Override
    public WebTarget getEndpoint(URI uri)
    {
        return getEndpoint(uri, true);
    }
    
    public WebTarget getEndpoint(URI uri, boolean delegateWebID)
    {
        WebTarget endpoint = super.getEndpoint(uri);
        
        if (delegateWebID && getSecurityContext() != null && getApplication() != null &&
                !getApplication().getBaseURI().relativize(uri).isAbsolute())
        {
            ClientRequestFilter filter = getClientAuthFilter(getSecurityContext());
            if (filter != null) endpoint.register(filter);
        }
        
        return endpoint;
    }

    public Application getApplication()
    {
        return application;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    public URI getRootContextURI()
    {
        return URI.create(getHttpServletRequest().getRequestURL().toString()).
                resolve(getHttpServletRequest().getContextPath() + "/");
    }
    
}