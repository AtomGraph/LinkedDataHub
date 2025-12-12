/*
 * Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>.
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
package com.atomgraph.linkeddatahub.server.model.impl;

import jakarta.ws.rs.ForbiddenException;
import org.junit.Test;

import java.net.URI;

/**
 * Unit tests for ProxyResourceBase SSRF protection.
 * Tests the validateNotInternalURL method to ensure it properly blocks access to internal addresses.
 *
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/250">LNK-009: SSRF vulnerability</a>
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ProxyResourceBaseTest
{

    @Test(expected = IllegalArgumentException.class)
    public void testNullURI()
    {
        ProxyResourceBase.validateNotInternalURL(null);
    }

    @Test(expected = ForbiddenException.class)
    public void testLinkLocalIPv4Blocked()
    {
        ProxyResourceBase.validateNotInternalURL(URI.create("http://169.254.1.1:8080/test"));
    }

    @Test(expected = ForbiddenException.class)
    public void testPrivateClass10Blocked()
    {
        ProxyResourceBase.validateNotInternalURL(URI.create("http://10.0.0.1:8080/test"));
    }

    @Test(expected = ForbiddenException.class)
    public void testPrivateClass172Blocked()
    {
        ProxyResourceBase.validateNotInternalURL(URI.create("http://172.16.0.0:8080/test"));
    }

    @Test(expected = ForbiddenException.class)
    public void testPrivateClass192Blocked()
    {
        ProxyResourceBase.validateNotInternalURL(URI.create("http://192.168.1.1:8080/test"));
    }

    @Test
    public void testExternalURLAllowed()
    {
        // Public IPs should be allowed (no exception thrown)
        ProxyResourceBase.validateNotInternalURL(URI.create("http://8.8.8.8:80/test"));
    }

    @Test
    public void testPublicDomainAllowed()
    {
        // Public domains should be allowed (no exception thrown)
        ProxyResourceBase.validateNotInternalURL(URI.create("http://example.org/test"));
    }

    @Test
    public void testHTTPSAllowed()
    {
        // HTTPS to public domain should be allowed (no exception thrown)
        ProxyResourceBase.validateNotInternalURL(URI.create("https://www.w3.org/ns/ldp"));
    }
}
