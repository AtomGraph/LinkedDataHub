/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import java.io.IOException;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;

/**
 * Attempts to make backend (triplestore) proxy cache layer transparent by invalidating cache entries that potentially become stale after a write/update request.
 * Currently implemented as a crude URL pattern-based heuristic. This filter works correctly if HTTP tests pass with both enabled and disabled proxy cache.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class BackendInvalidationFilter implements ContainerResponseFilter
{

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject javax.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> app;
    
    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        if (getApplication().isEmpty()) return;
        if (!getApplication().get().canAs(EndUserApplication.class) && !getApplication().get().canAs(AdminApplication.class)) return; // skip "primitive" apps
        if (getAdminApplication().getService().getProxy() == null) return;
        
        if (req.getMethod().equals(HttpMethod.POST) || req.getMethod().equals(HttpMethod.PUT) || req.getMethod().equals(HttpMethod.DELETE) || req.getMethod().equals(HttpMethod.PATCH))
        {
            // ban all admin/ entries when the admin dataset is changed - not perfect, but works
            if (!getAdminApplication().getBaseURI().relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) // URL is relative to the admin app's base URI
            {
                ban(getAdminApplication().getService().getProxy(), getAdminApplication().getBaseURI().toString()).close();
//                ban(getAdminApplication().getService().getProxy(), FOAF.Agent.getURI()).close();
                ban(getAdminApplication().getService().getProxy(), "foaf:Agent").close(); // queries use prefixed names instead of absolute URIs
//                ban(getAdminApplication().getService().getProxy(), ACL.AuthenticatedAgent.getURI()).close();
                ban(getAdminApplication().getService().getProxy(), "acl:AuthenticatedAgent").close();
            }
            
            ban(getApplication().get().getService().getProxy(), req.getUriInfo().getAbsolutePath().toString()).close();
            ban(getApplication().get().getService().getProxy(), getApplication().get().getBaseURI().relativize(req.getUriInfo().getAbsolutePath()).toString()).close(); // URIs can be relative in queries
        }
    }
    
    public Response ban(Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
        return getClient().target(proxy.getURI()).request().
            header("X-Escaped-Request-URI", UriComponent.encode(url, UriComponent.Type.UNRESERVED)). // the value has to be URL-encoded in order to match request URLs in Varnish
            method("BAN", Response.class);
    }

    public AdminApplication getAdminApplication()
    {
        if (getApplication().get().canAs(EndUserApplication.class))
            return getApplication().get().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().get().as(AdminApplication.class);
    }
    
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
    {
        return app.get();
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
 
    public Client getClient()
    {
        return getSystem().getClient();
    }
    
}
