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
package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.linkeddatahub.Application;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Set;
import org.apache.jena.rdf.model.ResourceFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;

/**
 * Unit tests for the OAuth referer check: the login sends the ID token to the referer, so only this instance's
 * dataspaces may be one.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class AuthorizeBaseTest
{

    private static final URI BASE = URI.create("https://localhost:4443/");
    private static final Set<String> DATASPACE_ORIGINS = Set.of("https://localhost:4443", "https://admin.localhost:4443", "https://northwind.localhost:4443");

    @Mock private Application system;

    @BeforeEach
    public void setUp()
    {
        // matchApp() matches by origin
        lenient().when(system.matchApp(any(URI.class))).thenAnswer(invocation ->
        {
            URI uri = invocation.getArgument(0);
            String origin = uri.getScheme() + "://" + uri.getHost() + (uri.getPort() == -1 ? "" : ":" + uri.getPort());
            return DATASPACE_ORIGINS.contains(origin) ? ResourceFactory.createResource(origin + "/") : null;
        });
    }

    @Test
    public void testNoRefererGivesBase()
    {
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, null));
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, ""));
    }

    @Test
    public void testRelativeRefererResolved()
    {
        assertEquals(URI.create("https://localhost:4443/some/doc/?mode=edit"), AuthorizeBase.checkReferer(system, BASE, "/some/doc/?mode=edit"));
        assertEquals(URI.create("https://localhost:4443/some/doc/"), AuthorizeBase.checkReferer(system, BASE, "some/doc/"));
    }

    @Test
    public void testSameOriginRefererKept()
    {
        assertEquals(URI.create("https://localhost:4443/some/doc/?uri=https%3A%2F%2Fexample.org%2F"),
            AuthorizeBase.checkReferer(system, BASE, "https://localhost:4443/some/doc/?uri=https%3A%2F%2Fexample.org%2F"));
    }

    @Test
    public void testOtherDataspaceRefererKept()
    {
        assertEquals(URI.create("https://northwind.localhost:4443/customers/"), AuthorizeBase.checkReferer(system, BASE, "https://northwind.localhost:4443/customers/"));
        assertEquals(URI.create("https://admin.localhost:4443/acl/agents/"), AuthorizeBase.checkReferer(system, BASE, "https://admin.localhost:4443/acl/agents/"));
    }

    @Test
    public void testForeignOriginRefererRefused()
    {
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://evil.example/"));
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "//evil.example/")); // scheme-relative
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://localhost:4444/")); // another port
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "http://localhost:4443/")); // another scheme
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://localhost:4443.evil.example/"));
    }

    @Test
    public void testNonHttpRefererRefused()
    {
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "javascript:alert(document.cookie)"));
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "data:text/html,hello"));
    }

    @Test
    public void testMalformedRefererRefused()
    {
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://evil.example\\@localhost:4443/"));
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://localhost:4443/\r\nSet-Cookie: x=y"));
    }

    @Test
    public void testUserInfoRefererRefused()
    {
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, "https://evil.example@localhost:4443/"));
    }

    /** The login appends its own fragment carrying the token */
    @Test
    public void testRefererFragmentDropped()
    {
        assertEquals(URI.create("https://localhost:4443/some/doc/"), AuthorizeBase.checkReferer(system, BASE, "https://localhost:4443/some/doc/#section"));
    }

    /** The login reads the referer back from the state value */
    @Test
    public void testStateReferer()
    {
        String stateValue = Base64.getEncoder().encodeToString("abc123;https://evil.example/;x".getBytes(StandardCharsets.UTF_8));
        assertEquals("https://evil.example/;x", LoginBase.getReferer(stateValue));
        assertEquals(BASE, AuthorizeBase.checkReferer(system, BASE, LoginBase.getReferer(stateValue)));

        assertNull(LoginBase.getReferer(Base64.getEncoder().encodeToString("abc123".getBytes(StandardCharsets.UTF_8))));
        assertNull(LoginBase.getReferer("not base64!"));
    }

}
