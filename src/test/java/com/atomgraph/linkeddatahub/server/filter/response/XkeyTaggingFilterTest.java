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
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.mockito.Mockito.when;

/**
 * Tests the surrogate keys put on responses for the frontend cache. They have to be exactly the strings
 * {@link CacheInvalidationFilter} purges by: a key that differs by a byte evicts nothing, and the stale copy stays.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class XkeyTaggingFilterTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final String ADMIN_URI = "urn:linkeddatahub:apps/admin";

    @Mock private ContainerRequestContext request;
    @Mock private ContainerResponseContext response;
    @Mock private UriInfo uriInfo;
    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private Dataspace dataspace;
    @Mock private EndUserDataspace endUser;
    @Mock private AdminDataspace admin;

    private XkeyTaggingFilter filter;
    private MultivaluedMap<String, Object> headers;

    @BeforeEach
    public void setUp()
    {
        filter = new XkeyTaggingFilter();
        filter.system = system;
        filter.app = () -> Optional.of(dataspace);

        headers = new MultivaluedHashMap<>();

        when(system.getFrontendProxy()).thenReturn(URI.create("http://varnish-frontend:6060/"));
        when(request.getMethod()).thenReturn("GET");
        when(request.getUriInfo()).thenReturn(uriInfo);
        when(uriInfo.getAbsolutePath()).thenReturn(URI.create("https://localhost:4443/people/alice/"));
        when(response.getHeaders()).thenReturn(headers);
        when(dataspace.getBaseURI()).thenReturn(BASE_URI);
        when(dataspace.canAs(EndUserDataspace.class)).thenReturn(true);
        when(dataspace.as(EndUserDataspace.class)).thenReturn(endUser);
        when(endUser.getAdminDataspace()).thenReturn(admin);
        when(admin.getURI()).thenReturn(ADMIN_URI);
    }

    private String xkey()
    {
        Object value = headers.getFirst(XkeyTaggingFilter.HEADER_NAME);

        return value != null ? value.toString() : null;
    }

    /** The document, its parent container, and the dataspace pair's access-control scope. */
    @Test
    public void testTagsDocumentParentAndScope() throws IOException
    {
        filter.filter(request, response);

        assertEquals("https://localhost:4443/people/alice/ https://localhost:4443/people/ " + ADMIN_URI, xkey());
    }

    @Test
    public void testRootHasNoParent() throws IOException
    {
        when(uriInfo.getAbsolutePath()).thenReturn(BASE_URI);

        filter.filter(request, response);

        assertEquals(BASE_URI + " " + ADMIN_URI, xkey());
    }

    /** A document without a trailing slash still has the container it sits in as its parent. */
    @Test
    public void testParentOfNonContainerPath()
    {
        assertEquals(URI.create("https://localhost:4443/"), XkeyTaggingFilter.getParent(URI.create("https://localhost:4443/ns"), BASE_URI));
        assertEquals(URI.create("https://localhost:4443/people/"), XkeyTaggingFilter.getParent(URI.create("https://localhost:4443/people/alice/"), BASE_URI));
        assertNull(XkeyTaggingFilter.getParent(BASE_URI, BASE_URI));
    }

    /** The admin dataspace is its own scope, so a change there evicts its own responses as well as the end-user ones. */
    @Test
    public void testAdminDataspaceIsItsOwnScope()
    {
        when(dataspace.canAs(EndUserDataspace.class)).thenReturn(false);
        when(dataspace.canAs(AdminDataspace.class)).thenReturn(true);
        when(dataspace.getURI()).thenReturn(ADMIN_URI);

        assertEquals(ADMIN_URI, XkeyTaggingFilter.getAccessControlScope(dataspace));
    }

    @Test
    public void testEndUserScopeIsItsAdminDataspace()
    {
        assertEquals(ADMIN_URI, XkeyTaggingFilter.getAccessControlScope(dataspace));
    }

    /** Only reads are cached, so only reads are tagged. */
    @Test
    public void testWriteNotTagged() throws IOException
    {
        when(request.getMethod()).thenReturn("PUT");

        filter.filter(request, response);

        assertNull(xkey());
    }

    @Test
    public void testNoTagsWithoutFrontendCache() throws IOException
    {
        when(system.getFrontendProxy()).thenReturn(null);

        filter.filter(request, response);

        assertNull(xkey());
    }

    @Test
    public void testNoTagsWithoutDataspace() throws IOException
    {
        filter.app = () -> Optional.empty();

        filter.filter(request, response);

        assertNull(xkey());
    }

    @Test
    public void testTagsAreSpaceSeparatedWithoutDuplicates()
    {
        // the root's own URI is not repeated as a parent
        assertEquals(List.of(BASE_URI.toString(), ADMIN_URI), List.copyOf(XkeyTaggingFilter.getTags(BASE_URI, BASE_URI, ADMIN_URI)));
    }

}
