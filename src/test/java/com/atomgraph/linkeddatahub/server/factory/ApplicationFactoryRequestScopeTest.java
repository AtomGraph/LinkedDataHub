/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.factory;

import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.container.PreMatching;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import org.glassfish.hk2.api.TypeLiteral;
import org.glassfish.hk2.utilities.binding.AbstractBinder;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.process.internal.RequestScoped;
import org.glassfish.jersey.server.ApplicationHandler;
import org.glassfish.jersey.server.ContainerRequest;
import org.glassfish.jersey.server.ContainerResponse;
import org.glassfish.jersey.server.ResourceConfig;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

/**
 * Tests that {@link ApplicationFactory} provides an empty dataspace, not null, when a request is refused before
 * <code>ApplicationFilter</code> sets it. The request scope caches whatever the factory provides, but takes a cached
 * null for a missing instance, so the second lookup in the same request failed with <code>IllegalStateException</code>
 * ("already seeded in this scope") and turned the refusal into a 500. Crawlers requesting
 * <code>?accept=application%2Frdf+xml</code>, whose unencoded <code>+</code> decodes to a space, hit it about 2,500
 * times a day on linkeddatahub.com.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationFactoryRequestScopeTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final String REFUSE_HEADER = "X-Refuse";
    private static final String DATASPACE_HEADER = "X-Dataspace";

    @Path("/")
    public static class RootResource
    {

        @GET
        public String get()
        {
            return "root";
        }

    }

    /**
     * Stands in for <code>ApplicationFilter</code>: refuses the request before setting the dataspace when asked to,
     * like its <code>setAccept()</code> does for a malformed <code>accept</code> parameter.
     */
    @PreMatching
    @Priority(700)
    public static class DataspaceFilter implements ContainerRequestFilter
    {

        @Override
        public void filter(ContainerRequestContext request)
        {
            if (request.getHeaderString(REFUSE_HEADER) != null) throw new BadRequestException("Refused before the dataspace was set");

            request.setProperty(LDS.Dataspace.getURI(), Optional.of(mock(Dataspace.class)));
        }

    }

    /**
     * Stands in for the response filters that each look the dataspace up, <code>ResponseHeadersFilter</code> and
     * <code>XkeyTaggingFilter</code>: the second lookup of a request is the one that used to fail.
     */
    public static class DataspaceLookupFilter implements ContainerResponseFilter
    {

        @Inject jakarta.inject.Provider<Optional<Dataspace>> app;

        @Override
        public void filter(ContainerRequestContext request, ContainerResponseContext response)
        {
            response.getHeaders().add(DATASPACE_HEADER, app.get().isPresent() ? "present" : "empty");
        }

    }

    @Priority(100)
    public static class FirstLookupFilter extends DataspaceLookupFilter {}

    @Priority(200)
    public static class SecondLookupFilter extends DataspaceLookupFilter {}

    private ContainerResponse get(boolean refuse) throws Exception
    {
        ResourceConfig config = new ResourceConfig(RootResource.class, DataspaceFilter.class, FirstLookupFilter.class, SecondLookupFilter.class);
        config.register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(ApplicationFactory.class).to(new TypeLiteral<Optional<Dataspace>>() {}).
                in(RequestScoped.class);
            }
        });

        ContainerRequest request = new ContainerRequest(BASE_URI, BASE_URI, "GET", null, new MapPropertiesDelegate(), null);
        if (refuse) request.header(REFUSE_HEADER, "true");

        return new ApplicationHandler(config).apply(request).get();
    }

    @Test
    public void refusedRequestKeepsItsStatus() throws Exception
    {
        ContainerResponse response = get(true);

        assertEquals(400, response.getStatus());
        assertEquals(List.of("empty", "empty"), response.getHeaders().get(DATASPACE_HEADER));
    }

    @Test
    public void matchedRequestSeesTheDataspaceTwice() throws Exception
    {
        ContainerResponse response = get(false);

        assertEquals(200, response.getStatus());
        assertEquals(List.of("present", "present"), response.getHeaders().get(DATASPACE_HEADER));
    }

}
