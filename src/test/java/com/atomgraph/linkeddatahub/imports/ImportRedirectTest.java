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
package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.client.RedirectStub;
import com.atomgraph.linkeddatahub.client.RedirectingClient;
import com.atomgraph.linkeddatahub.imports.stream.csv.ClientResponseSupplier;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.core.Response;
import java.io.InputStream;
import java.net.URI;
import java.security.KeyStore;
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

/**
 * Tests that import sources and queries are fetched with every redirect hop validated, through the import client,
 * which follows redirects on its own elsewhere.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportRedirectTest
{

    private static final String PASSWORD = "changeit";

    private RedirectStub stub;
    private Client client;
    private GraphStoreClient gsc;
    private RedirectingClient redirectingClient;

    @BeforeEach
    public void setUp() throws Exception
    {
        stub = new RedirectStub();
        client = Application.getClient(load("agent.p12"), PASSWORD, load("agent-trust.p12"), 20, 100, null, true, null, null, null, null, null);
        gsc = GraphStoreClient.create(client, new MediaTypes());
        redirectingClient = new RedirectingClient(stub.validator());
    }

    @AfterEach
    public void tearDown()
    {
        stub.close();
        client.close();
    }

    /** An import source redirecting to a denied address: 502, and the address is never requested */
    @Test
    public void sourceRedirectToDeniedAddressIsRefused()
    {
        URI internal = stub.internalURI("/internal.csv");
        ClientResponseSupplier supplier = new ClientResponseSupplier(gsc, redirectingClient, stub.redirect(302, internal.toString()));

        BadGatewayException ex = assertThrows(BadGatewayException.class, () -> supplier.get().close());
        assertTrue(ex.getMessage().contains(internal.toString()), ex.getMessage());
        assertEquals(List.of(), stub.internalRequests);
    }

    /** An import source behind allowed redirects is fetched */
    @Test
    public void sourceRedirectIsFollowed()
    {
        ClientResponseSupplier supplier = new ClientResponseSupplier(gsc, redirectingClient, stub.redirect(307, stub.redirect(303, "/data.ttl").toString()));

        try (Response response = supplier.get())
        {
            assertEquals(200, response.getStatus());
            assertEquals(RedirectStub.DOCUMENT, response.readEntity(String.class));
        }
    }

    /** An import query redirecting to a denied address: 502, and the address is never requested */
    @Test
    public void queryRedirectToDeniedAddressIsRefused()
    {
        URI queryURI = URI.create(stub.redirect(302, stub.internalURI("/query").toString()) + "#this");
        QueryLoader loader = new QueryLoader(queryURI, "http://example.org/", gsc, redirectingClient);

        assertThrows(BadGatewayException.class, loader::get);
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A redirected RDF document resolves relative URIs against the requested URI */
    @Test
    public void modelBaseIsRequestedURI()
    {
        String uri = stub.redirect(303, "card.ttl").toString();

        Model model = gsc.getModel(redirectingClient, uri);

        assertTrue(model.contains(ResourceFactory.createResource(uri + "#me"), RDF.type), model.toString());
    }

    private static KeyStore load(String name) throws Exception
    {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        try (InputStream in = RedirectStub.class.getResourceAsStream("ssl/" + name))
        {
            keyStore.load(in, PASSWORD.toCharArray());
        }
        return keyStore;
    }

}
