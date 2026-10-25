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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.model.impl.SPARQLEndpointImpl;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests what a write evicts from the frontend cache. The frontend knows responses by path, so it is purged by the surrogate
 * keys {@link XkeyTaggingFilter} puts on them - never by a URL ban, which could not match an absolute URI there.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class CacheInvalidationFilterTest
{

    private static final URI FRONTEND_PROXY = URI.create("http://varnish-frontend:6060/");
    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final URI ADMIN_BASE_URI = URI.create("https://admin.localhost:4443/");
    private static final String ADMIN_URI = "urn:linkeddatahub:apps/admin";

    @Mock private ContainerRequestContext request;
    @Mock private ContainerResponseContext response;
    @Mock private UriInfo uriInfo;
    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private ServiceContext serviceContext;
    @Mock private Service service;
    @Mock private Dataspace dataspace;
    @Mock private EndUserDataspace endUser;
    @Mock private AdminDataspace admin;

    private CacheInvalidationFilter filter;
    private List<String> calls;

    @BeforeEach
    public void setUp()
    {
        calls = new ArrayList<>();
        filter = new CacheInvalidationFilter()
        {
            @Override
            public Response xkeyPurge(URI proxyURI, String tag)
            {
                calls.add("XKEY-PURGE " + proxyURI + " " + tag);
                return mock(Response.class);
            }

            @Override
            public Response ban(URI proxyURI, String url)
            {
                calls.add("BAN " + proxyURI + " " + url);
                return mock(Response.class);
            }
        };
        filter.system = system;
        filter.app = () -> Optional.of(dataspace);

        when(system.getFrontendProxy()).thenReturn(FRONTEND_PROXY);
        when(system.getServiceContext(any())).thenReturn(serviceContext);
        when(serviceContext.getBackendProxy()).thenReturn(null); // only the frontend is under test

        // an end-user dataspace paired with its admin one
        when(dataspace.getBaseURI()).thenReturn(BASE_URI);
        when(dataspace.getService()).thenReturn(service);
        when(dataspace.canAs(EndUserDataspace.class)).thenReturn(true);
        when(dataspace.as(EndUserDataspace.class)).thenReturn(endUser);
        when(endUser.getAdminDataspace()).thenReturn(admin);
        when(admin.getBaseURI()).thenReturn(ADMIN_BASE_URI);
        when(admin.getService()).thenReturn(service);
        when(admin.getURI()).thenReturn(ADMIN_URI);
        when(admin.canAs(AdminDataspace.class)).thenReturn(true);
        when(admin.as(AdminDataspace.class)).thenReturn(admin);

        when(request.getUriInfo()).thenReturn(uriInfo);
        when(uriInfo.getMatchedResources()).thenReturn(List.of(mock(DocumentHierarchyGraphStoreImpl.class)));
        when(response.getStatusInfo()).thenReturn(Response.Status.NO_CONTENT);
    }

    private void write(String method, URI uri)
    {
        when(request.getMethod()).thenReturn(method);
        when(uriInfo.getAbsolutePath()).thenReturn(uri);
    }

    private boolean purged(String tag)
    {
        return calls.contains("XKEY-PURGE " + FRONTEND_PROXY + " " + tag);
    }

    /** A write evicts the document and its parent container, whose listing it changes. */
    @Test
    public void testWritePurgesDocumentAndParent() throws IOException
    {
        write("PATCH", URI.create("https://localhost:4443/people/alice/"));

        filter.filter(request, response);

        assertTrue(purged("https://localhost:4443/people/alice/"), calls.toString());
        assertTrue(purged("https://localhost:4443/people/"), calls.toString());
        // a write to the end-user dataspace leaves the rest of it alone
        assertFalse(purged(ADMIN_URI), calls.toString());
    }

    /** The frontend no longer handles BAN, so it must not be sent one. */
    @Test
    public void testFrontendNeverBanned() throws IOException
    {
        write("DELETE", URI.create("https://localhost:4443/people/alice/"));

        filter.filter(request, response);

        assertTrue(calls.stream().noneMatch(call -> call.startsWith("BAN " + FRONTEND_PROXY)), calls.toString());
    }

    /** A created document is evicted under its Location, together with the container it was created in. */
    @Test
    public void testCreatePurgesLocationAndParent() throws IOException
    {
        write("POST", URI.create("https://localhost:4443/people/"));
        when(response.getHeaderString(HttpHeaders.LOCATION)).thenReturn("https://localhost:4443/people/bob/");

        filter.filter(request, response);

        assertTrue(purged("https://localhost:4443/people/bob/"), calls.toString());
        assertTrue(purged("https://localhost:4443/people/"), calls.toString());
    }

    /** An access-control change in the admin dataspace can decide who reads any document of the pair. */
    @Test
    public void testAdminWritePurgesAccessControlScope() throws IOException
    {
        filter.app = () -> Optional.of(admin);
        write("DELETE", URI.create("https://admin.localhost:4443/acl/authorizations/public/"));

        filter.filter(request, response);

        assertTrue(purged(ADMIN_URI), calls.toString());
    }

    /** A failed write changed nothing. */
    @Test
    public void testFailedAdminWriteDoesNotPurgeScope() throws IOException
    {
        filter.app = () -> Optional.of(admin);
        write("DELETE", URI.create("https://admin.localhost:4443/acl/authorizations/public/"));
        when(response.getStatusInfo()).thenReturn(Response.Status.FORBIDDEN);

        filter.filter(request, response);

        assertFalse(purged(ADMIN_URI), calls.toString());
    }

    /** A SPARQL query sent by POST is not a write, and must not empty the dataspace's cache. */
    @Test
    public void testAdminQueryByPostDoesNotPurgeScope() throws IOException
    {
        filter.app = () -> Optional.of(admin);
        write("POST", URI.create("https://admin.localhost:4443/sparql"));
        when(response.getStatusInfo()).thenReturn(Response.Status.OK);
        when(uriInfo.getMatchedResources()).thenReturn(List.of(mock(SPARQLEndpointImpl.class)));

        filter.filter(request, response);

        assertFalse(purged(ADMIN_URI), calls.toString());
    }

    @Test
    public void testNothingPurgedWithoutFrontendProxy() throws IOException
    {
        when(system.getFrontendProxy()).thenReturn(null);
        write("PATCH", URI.create("https://localhost:4443/people/alice/"));

        filter.filter(request, response);

        assertEquals(List.of(), calls);
    }

}
