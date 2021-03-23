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
import javax.ws.rs.client.Invocation;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;

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
        if (req.getMethod().equals(HttpMethod.POST) || req.getMethod().equals(HttpMethod.PUT) || req.getMethod().equals(HttpMethod.DELETE) || req.getMethod().equals(HttpMethod.PATCH))
        {
            URI graphUrl = UriBuilder.fromUri(getAdminBaseURI()).path("graphs/").build();
            if (!graphUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(getAdminBaseURI());
            
            URI aclUrl = UriBuilder.fromUri(getAdminBaseURI()).path("acl/").build();
            if (!aclUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(aclUrl, URI.create(FOAF.Agent.getURI()), URI.create(ACL.AuthenticatedAgent.getURI()));

            URI modelUrl = UriBuilder.fromUri(getAdminBaseURI()).path("model/").build();
            if (!modelUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(modelUrl);

            URI sitemapUrl = UriBuilder.fromUri(getAdminBaseURI()).path("sitemap/").build();
            if (!sitemapUrl.relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) ban(sitemapUrl);
        }
    }
    
    public void ban(URI... resources)
    {
        final EndUserApplication endUserApp;
        final AdminApplication adminApp;
        
        if (getApplication().canAs(EndUserApplication.class))
        {
            endUserApp = getApplication().as(EndUserApplication.class);
            adminApp = endUserApp.getAdminApplication();
        }
        else
        {
            adminApp = getApplication().as(AdminApplication.class);
            endUserApp = adminApp.getEndUserApplication();
        }
        
        if (endUserApp.getService().getProxy() != null) ban(endUserApp.getService().getProxy(), resources).close(); // release connection
        if (adminApp.getService().getProxy() != null) ban(adminApp.getService().getProxy(), resources).close();
    }
    
    public Response ban(Resource proxy, URI... resources)
    {
        if (resources == null) throw new IllegalArgumentException("Resource cannot be null");
        
        if (resources.length > 0)
        {
            // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
            Invocation.Builder builder = getClient().target(proxy.getURI()).request();

            for (URI uri : resources) builder = builder.header("X-Escaped-Request-URI", UriComponent.encode(uri.toString(), UriComponent.Type.UNRESERVED));

            return builder.method("BAN", Response.class);
        }

        return null;
    }
    
    protected URI getAdminBaseURI()
    {
        return getApplication().canAs(EndUserApplication.class) ?
            getApplication().as(EndUserApplication.class).getAdminApplication().getBaseURI() :
            getApplication().getBaseURI();
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
