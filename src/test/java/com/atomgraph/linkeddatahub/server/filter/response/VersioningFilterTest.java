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

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.GraphVersioningService;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests the fire/skip conditions of the versioning response filter.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class VersioningFilterTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final URI DOC_URI = URI.create("https://localhost:4443/docs/one/");
    private static final String APP_URI = "urn:linkeddatahub:apps/end-user";

    @Mock private ContainerRequestContext request;
    @Mock private ContainerResponseContext response;
    @Mock private UriInfo uriInfo;
    @Mock private SecurityContext securityContext;
    @Mock private Agent agent;
    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private com.atomgraph.linkeddatahub.apps.model.Application application;
    @Mock private com.atomgraph.linkeddatahub.model.Service service;
    @Mock private ServiceContext serviceContext;
    @Mock private GraphVersioningService versioningService;
    @Mock private DocumentHierarchyGraphStoreImpl graphStore;

    private VersioningFilter filter;

    @BeforeEach
    public void setUp()
    {
        filter = new VersioningFilter();
        filter.system = system;
        filter.app = () -> Optional.of(application);

        // a qualifying document write; individual tests break one condition at a time
        when(request.getMethod()).thenReturn("PUT");
        when(request.getProperty(AC.uri.getURI())).thenReturn(null);
        when(request.getUriInfo()).thenReturn(uriInfo);
        when(request.getSecurityContext()).thenReturn(securityContext);
        when(response.getStatusInfo()).thenReturn(Response.Status.CREATED);
        when(uriInfo.getMatchedResources()).thenReturn(List.of(graphStore));
        when(uriInfo.getAbsolutePath()).thenReturn(DOC_URI);
        when(securityContext.getUserPrincipal()).thenReturn(agent);
        when(agent.getURI()).thenReturn("https://localhost:4443/agents/one/#this");
        when(application.getURI()).thenReturn(APP_URI);
        when(application.getBaseURI()).thenReturn(BASE_URI);
        when(application.getService()).thenReturn(service);
        when(system.getGraphVersioningService()).thenReturn(versioningService);
        when(system.getServiceContext(service)).thenReturn(serviceContext);
        when(versioningService.getRepository(APP_URI)).thenReturn(Optional.of(new GraphVersioningService.Repository(null, "graphs")));
    }

    @Test
    public void testQualifyingWriteSchedulesCommit() throws IOException
    {
        filter.filter(request, response);

        verify(versioningService).commitAsync(serviceContext, APP_URI, BASE_URI, DOC_URI, "https://localhost:4443/agents/one/#this", "PUT");
    }

    @Test
    public void testGetIsSkipped() throws IOException
    {
        when(request.getMethod()).thenReturn("GET");

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testRedirectIsSkipped() throws IOException
    {
        when(response.getStatusInfo()).thenReturn(Response.Status.PERMANENT_REDIRECT);

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testErrorResponseIsSkipped() throws IOException
    {
        when(response.getStatusInfo()).thenReturn(Response.Status.FORBIDDEN);

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testProxyRequestIsSkipped() throws IOException
    {
        when(request.getProperty(AC.uri.getURI())).thenReturn(URI.create("https://remote.example/doc"));

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testUnmatchedApplicationIsSkipped() throws IOException
    {
        filter.app = () -> Optional.empty();

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testNonDocumentResourceIsSkipped() throws IOException
    {
        when(uriInfo.getMatchedResources()).thenReturn(List.of(new Object())); // e.g. the SPARQL endpoint or Settings resource

        filter.filter(request, response);

        verifyNoCommit();
    }

    @Test
    public void testUnconfiguredApplicationIsSkipped() throws IOException
    {
        when(versioningService.getRepository(APP_URI)).thenReturn(Optional.empty());

        filter.filter(request, response);

        verifyNoCommit();
    }

    private void verifyNoCommit()
    {
        verify(versioningService, never()).commitAsync(any(), anyString(), any(), any(), anyString(), anyString());
    }

}
