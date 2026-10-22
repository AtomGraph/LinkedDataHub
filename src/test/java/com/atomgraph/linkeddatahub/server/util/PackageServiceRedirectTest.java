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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.client.RedirectStub;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Package;
import jakarta.ws.rs.client.Client;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.util.List;
import org.apache.jena.rdf.model.ResourceFactory;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests that {@link PackageService} validates every redirect hop when fetching package descriptions and stylesheets,
 * with the system client, which follows redirects on its own elsewhere.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class PackageServiceRedirectTest
{

    private static final String PASSWORD = "changeit";
    private static final URI APP_BASE = URI.create("https://localhost:4443/");

    @TempDir Path packageRoot;

    private RedirectStub stub;
    private Client client;
    private PackageService service;
    private Dataspace app;

    @BeforeEach
    public void setUp() throws Exception
    {
        stub = new RedirectStub();
        client = Application.getClient(load("agent.p12"), PASSWORD, load("agent-trust.p12"), 20, 100, null, false, null, null, null, null, null);

        Application system = mock(Application.class);
        when(system.getRepository()).thenReturn(mock(PrefixGraphRepository.class));
        when(system.getURLValidator()).thenReturn(stub.validator());
        when(system.getClient()).thenReturn(client);
        when(system.getMediaTypes()).thenReturn(new MediaTypes());
        when(system.getPackageRoot()).thenReturn(packageRoot.toUri());
        service = new PackageService(system);

        app = mock(Dataspace.class);
        when(app.getBaseURI()).thenReturn(APP_BASE);
    }

    @AfterEach
    public void tearDown()
    {
        stub.close();
        client.close();
    }

    private Package declaring(URI stylesheet)
    {
        Package pkg = mock(Package.class);
        when(pkg.getURI()).thenReturn("https://packages.example.org/p/#this");
        when(pkg.getStylesheet()).thenReturn(ResourceFactory.createResource(stylesheet.toString()));
        return pkg;
    }

    /** A package description redirecting to a denied address does not resolve, and the address is never requested */
    @Test
    public void packageRedirectToDeniedAddressIsRefused()
    {
        URI packageURI = URI.create(stub.redirect(302, stub.internalURI("/internal").toString()) + "#this");

        assertNull(service.getPackage(packageURI.toString()));
        assertEquals(1, stub.publicRequests.size(), stub.publicRequests.toString());
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A stylesheet redirecting to a denied address is not copied, and the address is never requested */
    @Test
    public void stylesheetRedirectToDeniedAddressIsRefused() throws Exception
    {
        URI declared = stub.redirect(302, stub.internalURI("/internal.xsl").toString());

        assertEquals(declared, service.materializeStylesheet(declaring(declared), app));
        try (var files = Files.walk(packageRoot))
        {
            assertFalse(files.anyMatch(Files::isRegularFile), "nothing is copied");
        }
        assertEquals(List.of(), stub.internalRequests);
    }

    /** A stylesheet behind allowed redirects is copied */
    @Test
    public void stylesheetRedirectIsFollowed() throws Exception
    {
        Package pkg = declaring(stub.redirect(301, stub.redirect(302, "/style.xsl").toString()));

        URI copy = service.materializeStylesheet(pkg, app);

        String path = service.getStylesheetPath(pkg, URI.create(pkg.getStylesheet().getURI()));
        assertEquals(APP_BASE.resolve(PackageService.PUBLIC_PATH + path), copy);
        assertEquals(RedirectStub.DOCUMENT, Files.readString(packageRoot.resolve(path), StandardCharsets.UTF_8));
        assertEquals(3, stub.publicRequests.size(), stub.publicRequests.toString());
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
