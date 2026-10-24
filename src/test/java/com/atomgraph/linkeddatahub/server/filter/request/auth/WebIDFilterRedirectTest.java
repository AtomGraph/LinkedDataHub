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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.client.RedirectStub;
import jakarta.ws.rs.client.Client;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests that loading a WebID document runs the SSRF check on every redirect, against stub servers on loopback:
 * the WebID comes from the client certificate, so its document is fetched before anyone is authenticated.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDFilterRedirectTest
{

    private RedirectStub stub;
    private Client client;
    private WebIDFilter filter;

    @BeforeEach
    public void setUp() throws Exception
    {
        stub = new RedirectStub();
        client = Application.getNoCertClient(null, 20, 100, null, null, null, null, null, null);

        Application system = mock(Application.class);
        when(system.getURLValidator()).thenReturn(stub.validator());
        when(system.getNoCertClient()).thenReturn(client);

        filter = new WebIDFilter()
        {
            @Override
            public Application getSystem()
            {
                return system;
            }
        };
    }

    @AfterEach
    public void tearDown()
    {
        stub.close();
        client.close();
    }

    /** A WebID document redirecting to a denied address: 502, and the address is never requested */
    @Test
    public void redirectToDeniedAddressIsNotFollowed()
    {
        URI internal = stub.internalURI("/internal");
        URI webID = URI.create(stub.redirect(302, internal.toString()) + "#me");

        BadGatewayException ex = assertThrows(BadGatewayException.class, () -> filter.loadWebIDFromURI(webID));
        assertTrue(ex.getMessage().contains(internal.toString()), ex.getMessage());
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A WebID document behind an allowed redirect (e.g. {@code 303} to a representation) still loads */
    @Test
    public void allowedRedirectIsFollowed()
    {
        URI webID = URI.create(stub.redirect(303, "card.ttl") + "#me"); // a Location with nothing to percent-encode, so the WebID URI stays as written

        Model model = filter.loadWebIDFromURI(webID);

        // relative URIs resolve against the requested WebID document
        assertTrue(model.contains(ResourceFactory.createResource(webID.toString()), RDF.type), model.toString());
        assertEquals(2, stub.publicRequests.size(), stub.publicRequests.toString());
    }

}
