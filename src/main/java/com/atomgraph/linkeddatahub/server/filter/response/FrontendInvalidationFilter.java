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

import java.io.IOException;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.Response;
import org.apache.jena.rdf.model.Resource;

/**
 * Attempts to make frontend proxy cache layer transparent by invalidating cache entries that potentially become stale after a write/update request.
 * This filter works correctly if HTTP tests pass with both enabled and disabled proxy cache.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 400)
public class FrontendInvalidationFilter implements ContainerResponseFilter
{
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> app;
    
    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        if (getApplication().getFrontendProxy() == null) return;
        if (!resp.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL)) return;

        if (req.getMethod().equals(HttpMethod.POST) || req.getMethod().equals(HttpMethod.PUT) || req.getMethod().equals(HttpMethod.DELETE) || req.getMethod().equals(HttpMethod.PATCH))
            purge(getApplication().getFrontendProxy(), req.getUriInfo().getRequestUri().toString()).close();
    }
    
    /**
     * Purges URL from proxy cache.
     * 
     * @param proxy proxy resource
     * @param url URL to be banned
     * @return response from proxy
     */
    public Response purge(Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");

        // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
        return getClient().target(proxy.getURI()).request().
            method("PURGE", Response.class);
    }
    
    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return app.get();
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
     * Returns HTTP client instance.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return getSystem().getClient();
    }
    
}
