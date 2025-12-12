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

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import java.io.IOException;
import java.net.URI;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.util.Optional;
import java.util.Set;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;

/**
 * Attempts to make backend (triplestore) proxy cache layer transparent by invalidating cache entries that potentially become stale after a write/update request.
 * Currently implemented as a crude URL pattern-based heuristic. This filter works correctly if HTTP tests pass with both enabled and disabled proxy cache.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 400)
public class CacheInvalidationFilter implements ContainerResponseFilter
{
    
    /**
     * Name of the HTTP request header that is used to pass values of URLs for invalidation.
     */
    public static final String HEADER_NAME = "X-Escaped-Request-URI";
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> app;

    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        // If no application was matched (e.g., non-existent dataspace), skip cache invalidation
        if (!getApplication().isPresent()) return;

        if (req.getMethod().equals(HttpMethod.POST) && resp.getHeaderString(HttpHeaders.LOCATION) != null)
        {
            URI location = URI.create(resp.getHeaderString(HttpHeaders.LOCATION));
            URI parentURI = location.resolve("..").normalize();
            URI relativeParentURI = getApplication().get().getBaseURI().relativize(parentURI);

            banIfNotNull(getApplication().get().getFrontendProxy(), location.toString());
            banIfNotNull(getApplication().get().getService().getBackendProxy(), location.toString());
            // ban URI from authorization query results
            banIfNotNull(getAdminApplication().getService().getBackendProxy(), location.toString());

            // ban parent resource URI in order to avoid stale children data in containers
            banIfNotNull(getApplication().get().getFrontendProxy(), parentURI.toString());
            banIfNotNull(getApplication().get().getService().getBackendProxy(), parentURI.toString());

            if (!relativeParentURI.toString().isEmpty()) // URIs can be relative in queries
            {
                banIfNotNull(getApplication().get().getFrontendProxy(), relativeParentURI.toString());
                banIfNotNull(getApplication().get().getService().getBackendProxy(), relativeParentURI.toString());
            }

            // ban all results of queries that use forClass type
            if (req.getUriInfo().getQueryParameters().containsKey(AC.forClass.getLocalName()))
            {
                String forClass = req.getUriInfo().getQueryParameters().getFirst(AC.forClass.getLocalName());
                banIfNotNull(getApplication().get().getFrontendProxy(), forClass);
                banIfNotNull(getApplication().get().getService().getBackendProxy(), forClass);
            }
        }
        
        if (Set.of(HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE, HttpMethod.PATCH).contains(req.getMethod()))
        {
            // ban all admin. entries when the admin dataset is changed - not perfect, but works
            if (!getAdminApplication().getBaseURI().relativize(req.getUriInfo().getAbsolutePath()).isAbsolute()) // URL is relative to the admin app's base URI
            {
                banIfNotNull(getAdminApplication().getService().getBackendProxy(), getAdminApplication().getBaseURI().toString());
                banIfNotNull(getAdminApplication().getService().getBackendProxy(), "foaf:Agent"); // queries use prefixed names instead of absolute URIs
                banIfNotNull(getAdminApplication().getService().getBackendProxy(), "acl:AuthenticatedAgent");
            }

            if (req.getUriInfo().getAbsolutePath().toString().endsWith("/"))
            {
                banIfNotNull(getApplication().get().getFrontendProxy(), req.getUriInfo().getAbsolutePath().toString());
                banIfNotNull(getApplication().get().getService().getBackendProxy(), req.getUriInfo().getAbsolutePath().toString());
                // ban URI from authorization query results
                banIfNotNull(getAdminApplication().getService().getBackendProxy(), req.getUriInfo().getAbsolutePath().toString());

                // ban parent document URIs (those that have a trailing slash) in order to avoid stale children data in containers
                if (!req.getUriInfo().getAbsolutePath().equals(getApplication().get().getBaseURI()))
                {
                    URI parentURI = req.getUriInfo().getAbsolutePath().resolve("..").normalize();
                    URI relativeParentURI = getApplication().get().getBaseURI().relativize(parentURI);

                    // ban parent resource URI in order to avoid stale children data in containers
                    banIfNotNull(getApplication().get().getFrontendProxy(), parentURI.toString());
                    banIfNotNull(getApplication().get().getService().getBackendProxy(), parentURI.toString());

                    if (!relativeParentURI.toString().isEmpty()) // URIs can be relative in queries
                    {
                        banIfNotNull(getApplication().get().getFrontendProxy(), relativeParentURI.toString());
                        banIfNotNull(getApplication().get().getService().getBackendProxy(), relativeParentURI.toString());
                    }
                }
            }
        }
    }
    
    /**
     * Bans URL from proxy cache if proxy is not null.
     * Null-safe wrapper that handles the common pattern of banning and closing the response.
     *
     * @param proxy proxy resource (can be null)
     * @param url URL to be banned
     */
    public void banIfNotNull(Resource proxy, String url)
    {
        if (proxy != null)
            ban(proxy, url).close();
    }

    /**
     * Bans URL from proxy cache.
     *
     * @param proxy proxy resource
     * @param url URL to be banned
     * @return response from proxy
     */
    public Response ban(Resource proxy, String url)
    {
        if (proxy == null) throw new IllegalArgumentException("Proxy resource cannot be null");
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");

        return getClient().target(proxy.getURI()).request().
            header(HEADER_NAME, UriComponent.encode(url, UriComponent.Type.UNRESERVED)). // the value has to be URL-encoded in order to match request URLs in Varnish
            method("BAN", Response.class);
    }

    /**
     * Returns admin application of the current dataspace.
     *
     * @return admin application resource
     */
    public AdminApplication getAdminApplication()
    {
        com.atomgraph.linkeddatahub.apps.model.Application application = getApplication().get();
        if (application.canAs(EndUserApplication.class))
            return application.as(EndUserApplication.class).getAdminApplication();
        else
            return application.as(AdminApplication.class);
    }
    
    /**
     * Returns the current application.
     *
     * @return optional application resource
     */
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
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
