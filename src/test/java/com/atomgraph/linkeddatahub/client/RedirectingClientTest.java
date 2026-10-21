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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.Application;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.Response;
import java.io.InputStream;
import java.net.URI;
import java.security.KeyStore;
import java.util.List;
import org.glassfish.jersey.client.ClientProperties;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests that {@link RedirectingClient} validates every redirect hop before requesting it, and that the clients it
 * stands in for follow no redirect themselves.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RedirectingClientTest
{

    private static final String PASSWORD = "changeit";

    private RedirectStub stub;
    private Client client;
    private RedirectingClient redirectingClient;

    @BeforeEach
    public void start() throws Exception
    {
        stub = new RedirectStub();
        client = Application.getNoCertClient(load("agent-trust.p12"), 20, 100, null, null, null, null, null, null);
        redirectingClient = new RedirectingClient(stub.validator());
    }

    @AfterEach
    public void stop()
    {
        stub.close();
        client.close();
    }

    private Response get(URI uri)
    {
        return redirectingClient.get(client::target, uri, target -> target.request().get());
    }

    /** A redirect to a denied address is refused with 502 naming the hop, and the denied address is never requested */
    @Test
    public void redirectToDeniedAddressIsRefused()
    {
        for (int status : List.of(301, 302, 303, 307, 308))
        {
            URI internal = stub.internalURI("/internal");
            BadGatewayException ex = assertThrows(BadGatewayException.class, () -> get(stub.redirect(status, internal.toString())).close(), String.valueOf(status));
            assertTrue(ex.getMessage().contains(internal.toString()), ex.getMessage());
        }
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A denied address several allowed hops in is refused too */
    @Test
    public void deniedHopAfterAllowedHopsIsRefused()
    {
        URI uri = stub.redirect(302, stub.redirect(301, stub.internalURI("/internal").toString()).toString());
        BadGatewayException ex = assertThrows(BadGatewayException.class, () -> get(uri).close());
        assertTrue(ex.getMessage().contains("hop 2"), ex.getMessage());
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A chain of allowed redirects - absolute and relative, every status - is followed to the end */
    @Test
    public void allowedChainIsFollowed()
    {
        String to = "/document";
        for (int status : List.of(308, 307, 303, 302, 301)) to = stub.redirect(status, to).toString();

        try (Response response = get(URI.create(to)))
        {
            assertEquals(200, response.getStatus());
            assertEquals(RedirectStub.DOCUMENT, response.readEntity(String.class));
        }
        assertEquals(6, stub.publicRequests.size(), stub.publicRequests.toString());
    }

    /** {@link RedirectingClient#MAX_REDIRECTS} redirects are followed (see above), one more is refused before it is requested */
    @Test
    public void moreThanFiveHopsAreRefused()
    {
        BadGatewayException ex = assertThrows(BadGatewayException.class, () -> get(stub.publicURI("/loop/0")).close());
        assertTrue(ex.getMessage().contains("More than " + RedirectingClient.MAX_REDIRECTS + " redirects"), ex.getMessage());
        assertEquals(RedirectingClient.MAX_REDIRECTS + 1, stub.publicRequests.size(), stub.publicRequests.toString()); // /loop/0 to /loop/5
    }

    /** An unsafe request is not repeated at the redirect target: the caller gets the redirect, except after a 303 */
    @Test
    public void unsafeMethodFollowsOnlySeeOther()
    {
        for (int status : List.of(301, 302, 307, 308))
            try (Response response = redirectingClient.invoke(client::target, stub.redirect(status, "/document"), "POST",
                    (target, method) -> target.request().method(method, Entity.text("body"))))
            {
                assertEquals(status, response.getStatus());
            }
        assertEquals(4, stub.publicRequests.size(), stub.publicRequests.toString());

        stub.publicRequests.clear();
        try (Response response = redirectingClient.invoke(client::target, stub.redirect(303, "/document"), "POST",
                (target, method) -> "POST".equals(method) ? target.request().method(method, Entity.text("body")) : target.request().method(method)))
        {
            assertEquals(200, response.getStatus());
        }
        assertTrue(stub.publicRequests.get(1).startsWith("GET /document"), stub.publicRequests.toString());
    }

    /** The no-cert client (the anonymous proxy's and the WebID loader's) does not follow a redirect itself */
    @Test
    public void noCertClientDoesNotFollowRedirects()
    {
        try (Response response = client.target(stub.redirect(302, stub.internalURI("/internal").toString())).request().get())
        {
            assertEquals(302, response.getStatus());
        }
        assertEquals(List.of(), stub.internalRequests);
    }

    /** The certificate client, configured as the proxy's external client is, does not follow a redirect itself */
    @Test
    public void externalClientDoesNotFollowRedirects() throws Exception
    {
        Client external = Application.getClient(load("agent.p12"), PASSWORD, load("agent-trust.p12"), 20, 100, null, false, null, null, null, null, null);
        external.property(ClientProperties.FOLLOW_REDIRECTS, false);
        try (Response response = external.target(stub.redirect(302, stub.internalURI("/internal").toString())).request().get())
        {
            assertEquals(302, response.getStatus());
        }
        finally
        {
            external.close();
        }
        assertEquals(List.of(), stub.internalRequests);
    }

    private static KeyStore load(String name) throws Exception
    {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        try (InputStream in = RedirectingClientTest.class.getResourceAsStream("ssl/" + name))
        {
            keyStore.load(in, PASSWORD.toCharArray());
        }
        return keyStore;
    }

}
