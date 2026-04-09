/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import org.apache.jena.ontology.Ontology;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ProxyRequestFilter}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@RunWith(MockitoJUnitRunner.Silent.class)
public class ProxyRequestFilterTest
{

    @Mock com.atomgraph.linkeddatahub.Application system;
    @Mock MediaTypes mediaTypes;
    @Mock Request request;
    @Mock Ontology ontology;

    @InjectMocks ProxyRequestFilter filter;

    @Mock ContainerRequestContext requestContext;
    @Mock UriInfo uriInfo;
    @Mock DataManager dataManager;
    @Mock URLValidator urlValidator;
    @Mock Client externalClient;
    @Mock WebTarget webTarget;
    @Mock Invocation.Builder invocationBuilder;
    @Mock Response clientResponse;
    @Mock Resource registeredApp;

    private static final URI ADMIN_URI = URI.create("https://admin.localhost:4443/");
    private static final URI EXTERNAL_URI = URI.create("https://example.com/data");

    @Before
    public void setUp()
    {
        when(requestContext.getUriInfo()).thenReturn(uriInfo);
        when(requestContext.getProperty(LAPP.Application.getURI())).thenReturn(null);
        when(requestContext.getProperty(LAPP.Dataset.getURI())).thenReturn(null);
        when(system.getDataManager()).thenReturn(dataManager);
        when(dataManager.isMapped(anyString())).thenReturn(false);
        when(system.isEnableLinkedDataProxy()).thenReturn(false);
        filter.ontology = () -> Optional.empty();
    }

    /**
     * When the proxy is disabled, a {@code ?uri=} pointing to an unregistered external URL must be blocked.
     */
    @Test(expected = NotAllowedException.class)
    public void testUnregisteredUriBlockedWhenProxyDisabled() throws IOException
    {
        MultivaluedHashMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle("uri", EXTERNAL_URI.toString());
        when(uriInfo.getQueryParameters()).thenReturn(params);

        filter.filter(requestContext);
    }

    /**
     * When the proxy is disabled, a {@code ?uri=} pointing to a registered {@code lapp:Application}
     * must be allowed through — it is a first-party endpoint, not a third-party resource.
     */
    @Test
    public void testRegisteredAppAllowedWhenProxyDisabled() throws IOException
    {
        MultivaluedHashMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle("uri", ADMIN_URI.toString());
        when(uriInfo.getQueryParameters()).thenReturn(params);

        // matchApp() returns a non-null Resource for the admin app (registered lapp:Application)
        when(system.matchApp(ADMIN_URI)).thenReturn(registeredApp);

        // SSRF validator is a no-op (mock void method)
        when(system.getURLValidator()).thenReturn(urlValidator);

        // HTTP call chain: GET to the admin app
        when(system.getExternalClient()).thenReturn(externalClient);
        when(requestContext.getMethod()).thenReturn("GET");
        when(requestContext.getProperty(AgentContext.class.getCanonicalName())).thenReturn(null);
        when(mediaTypes.getReadable(Model.class)).thenReturn(List.of());
        when(mediaTypes.getReadable(ResultSet.class)).thenReturn(List.of());
        when(externalClient.target(ADMIN_URI)).thenReturn(webTarget);
        when(webTarget.request()).thenReturn(invocationBuilder);
        when(invocationBuilder.accept(any(MediaType[].class))).thenReturn(invocationBuilder);
        when(invocationBuilder.header(anyString(), any())).thenReturn(invocationBuilder);
        when(invocationBuilder.method(anyString())).thenReturn(clientResponse);

        // null media type triggers the early-return path in getResponse(Response)
        when(clientResponse.getHeaders()).thenReturn(new MultivaluedHashMap<>());
        when(clientResponse.getMediaType()).thenReturn(null);
        when(clientResponse.getStatus()).thenReturn(200);

        filter.filter(requestContext); // must not throw NotAllowedException
    }

}
