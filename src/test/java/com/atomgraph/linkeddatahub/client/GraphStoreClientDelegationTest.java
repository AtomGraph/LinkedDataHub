/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.WebTarget;
import java.net.URI;
import java.util.List;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isA;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the agent delegation of {@link GraphStoreClient}: requests to this instance's dataspaces carry it,
 * requests to other origins do not.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphStoreClientDelegationTest
{

    private static final URI BASE = URI.create("https://localhost:4443/");
    private static final URI DATASPACE_DOC = URI.create("https://admin.localhost:4443/doc");
    private static final URI EXTERNAL_DOC = URI.create("https://remote.example/doc");

    /** Targets on localhost:4443 and its subdomains are dataspaces */
    private static boolean isDataspace(URI uri)
    {
        return uri.getHost().endsWith("localhost") && uri.getPort() == 4443;
    }

    private static WebTarget target(AgentContext agentContext, URI uri)
    {
        Client client = mock(Client.class);
        WebTarget target = mock(WebTarget.class);
        when(client.target(uri)).thenReturn(target);
        when(target.getUri()).thenReturn(uri);

        GraphStoreClient.create(client, new MediaTypes()).
            delegation(BASE, agentContext, GraphStoreClientDelegationTest::isDataspace).
            getWebTarget(uri);
        return target;
    }

    private static IDTokenSecurityContext idTokenContext()
    {
        IDTokenSecurityContext context = mock(IDTokenSecurityContext.class);
        lenient().when(context.getJWTToken()).thenReturn("header.payload.signature");
        return context;
    }

    @Test
    public void testIDTokenDelegatedToDataspace()
    {
        WebTarget target = target(idTokenContext(), DATASPACE_DOC);

        verify(target).register(isA(IDTokenDelegationFilter.class));
        verify(target, never()).register(isA(WebIDDelegationFilter.class));
    }

    @Test
    public void testWebIDDelegatedToDataspace()
    {
        WebTarget target = target(mock(WebIDSecurityContext.class), DATASPACE_DOC);

        verify(target).register(isA(WebIDDelegationFilter.class));
        verify(target, never()).register(isA(IDTokenDelegationFilter.class));
    }

    /** Neither the ID token cookie nor On-Behalf-Of goes to another origin */
    @Test
    public void testNothingDelegatedToExternalOrigin()
    {
        for (AgentContext agentContext : List.of(idTokenContext(), mock(WebIDSecurityContext.class)))
        {
            WebTarget target = target(agentContext, EXTERNAL_DOC);

            verify(target, never()).register(any(Object.class));
        }
    }

    @Test
    public void testAnonymousNotDelegated()
    {
        WebTarget target = target(null, DATASPACE_DOC);

        verify(target, never()).register(any(Object.class));
    }

}
