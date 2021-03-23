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
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import java.io.IOException;
import java.net.URI;
import javax.inject.Inject;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Resource;

/**
 * Attempts to make proxy cache layer transparent by invalidating cache entries that potentially become stale after a write/update request.
 * Currently implemented as a crude URL pattern-based heuristic. This filter works correctly if HTTP tests pass with both enabled and disabled proxy cache.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class CacheInvalidationFilter implements ContainerResponseFilter
{

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject com.atomgraph.linkeddatahub.apps.model.Application app;
    
    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        if (getAdminApplication().getService().getProxy() == null) return;
        
        if (req.getMethod().equals(HttpMethod.POST) || req.getMethod().equals(HttpMethod.PUT) || req.getMethod().equals(HttpMethod.DELETE) || req.getMethod().equals(HttpMethod.PATCH))
        {
//            URI graphUrl = UriBuilder.fromUri(getAdminBaseURI()).path("graphs/").build();
//            if (!graphUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(getAdminBaseURI());
//            
//            URI aclUrl = UriBuilder.fromUri(getAdminBaseURI()).path("acl/").build();
//            if (!aclUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(aclUrl, URI.create(FOAF.Agent.getURI()), URI.create(ACL.AuthenticatedAgent.getURI()));
//
//            URI modelUrl = UriBuilder.fromUri(getAdminBaseURI()).path("model/").build();
//            if (!modelUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(modelUrl);
//
//            URI sitemapUrl = UriBuilder.fromUri(getAdminBaseURI()).path("sitemap/").build();
//            if (!sitemapUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(sitemapUrl);
            
            if (!getAdminApplication().getBaseURI().relativize(req.getUriInfo().getAbsolutePath()).isAbsolute())
            {
                ban(getAdminApplication().getService().getProxy(), getAdminApplication().getBaseURI());
                ban(getAdminApplication().getService().getProxy(), URI.create(FOAF.Agent.getURI()));
                ban(getAdminApplication().getService().getProxy(), URI.create(ACL.AuthenticatedAgent.getURI()));
            }
        }
    }
    
    public Response ban(Resource proxy, URI url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
        return getClient().target(proxy.getURI()).request().
            header("X-Escaped-Request-URI", url).
            method("BAN", Response.class);
    }

    public AdminApplication getAdminApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().as(AdminApplication.class);
    }
    
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return app;
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
