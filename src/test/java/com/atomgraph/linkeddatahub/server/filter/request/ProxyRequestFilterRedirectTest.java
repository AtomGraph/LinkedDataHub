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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.client.RedirectStub;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.server.ContainerRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests that the Linked Data proxy runs the SSRF check on every redirect an upstream answers with, against stub
 * servers on loopback.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ProxyRequestFilterRedirectTest
{

    private RedirectStub stub;
    private Client client;
    private ProxyRequestFilter filter;

    @BeforeEach
    public void setUp() throws Exception
    {
        stub = new RedirectStub();
        client = Application.getNoCertClient(null, 20, 100, null, null, null, null, null, null);

        Application system = mock(Application.class);
        when(system.getRepository()).thenReturn(mock(PrefixGraphRepository.class));
        when(system.isEnableLinkedDataProxy()).thenReturn(true);
        when(system.getURLValidator()).thenReturn(stub.validator());
        when(system.getExternalNoCertClient()).thenReturn(client);

        ContainerRequest request = new ContainerRequest(URI.create("https://localhost:4443/"),
            URI.create("https://localhost:4443/?uri=x"), "GET", null, new MapPropertiesDelegate(), null);
        request.header(HttpHeaders.ACCEPT, "text/turtle");

        filter = new ProxyRequestFilter();
        filter.mediaTypes = new MediaTypes();
        filter.request = request;
        filter.httpHeaders = request; // Jersey's container request is also the request's HttpHeaders
        filter.system = system;
    }

    @AfterEach
    public void tearDown()
    {
        stub.close();
        client.close();
    }

    /** An anonymous {@code GET ?uri=} for the given target */
    private ContainerRequestContext proxying(URI target)
    {
        ContainerRequestContext requestContext = mock(ContainerRequestContext.class);
        when(requestContext.getProperty(AC.uri.getURI())).thenReturn(target);
        when(requestContext.getAcceptableMediaTypes()).thenReturn(List.of(MediaType.valueOf("text/turtle")));
        when(requestContext.getMethod()).thenReturn("GET");
        UriInfo uriInfo = mock(UriInfo.class);
        when(uriInfo.getBaseUri()).thenReturn(URI.create("https://localhost:4443/"));
        when(requestContext.getUriInfo()).thenReturn(uriInfo);
        return requestContext;
    }

    /** An upstream redirecting to a denied address: 502, and the address is never requested */
    @Test
    public void redirectToDeniedAddressIsRefused() throws Exception
    {
        URI internal = stub.internalURI("/internal");
        ContainerRequestContext requestContext = proxying(stub.redirect(302, internal.toString()));

        BadGatewayException ex = assertThrows(BadGatewayException.class, () -> filter.filter(requestContext));
        assertTrue(ex.getMessage().contains(internal.toString()), ex.getMessage());
        verify(requestContext, never()).abortWith(any());
        assertEquals(List.of(), stub.internalRequests);
    }

    /** An upstream redirecting through allowed hops: the document at the end is served */
    @Test
    public void allowedRedirectsAreFollowed() throws Exception
    {
        URI target = stub.redirect(301, stub.redirect(303, "/document").toString());
        ContainerRequestContext requestContext = proxying(target);

        filter.filter(requestContext);

        ArgumentCaptor<Response> response = ArgumentCaptor.forClass(Response.class);
        verify(requestContext).abortWith(response.capture());
        assertEquals(200, response.getValue().getStatus());
        assertTrue(response.getValue().getEntity() instanceof Model);
        assertTrue(((Model)response.getValue().getEntity()).size() > 0);
        assertEquals(3, stub.publicRequests.size(), stub.publicRequests.toString());
    }

}
