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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import jakarta.ws.rs.BadRequestException;
import org.junit.Test;

import java.net.URI;

/**
 * Unit tests for WebIDFilter SSRF protection.
 * Tests the validateNotInternalURL method to ensure it properly blocks access to internal addresses.
 *
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/252">LNK-004: SSRF primitive via On-Behalf-Of header</a>
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDFilterTest
{

    @Test(expected = IllegalArgumentException.class)
    public void testNullURI()
    {
        WebIDFilter.validateNotInternalURL(null);
    }

    @Test(expected = BadRequestException.class)
    public void testLinkLocalIPv4Blocked()
    {
        WebIDFilter.validateNotInternalURL(URI.create("http://169.254.1.1:8080/webid#me"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass10Blocked()
    {
        WebIDFilter.validateNotInternalURL(URI.create("http://10.0.0.1:8080/webid#me"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass172Blocked()
    {
        WebIDFilter.validateNotInternalURL(URI.create("http://172.16.0.0:8080/webid#me"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass192Blocked()
    {
        WebIDFilter.validateNotInternalURL(URI.create("http://192.168.1.1:8080/webid#me"));
    }

    @Test
    public void testExternalURLAllowed()
    {
        // Public IPs should be allowed (no exception thrown)
        WebIDFilter.validateNotInternalURL(URI.create("http://8.8.8.8:80/webid#me"));
    }

    @Test
    public void testPublicDomainAllowed()
    {
        // Public domains should be allowed (no exception thrown)
        WebIDFilter.validateNotInternalURL(URI.create("http://example.org/webid#me"));
    }

    @Test
    public void testHTTPSAllowed()
    {
        // HTTPS to public domain should be allowed (no exception thrown)
        WebIDFilter.validateNotInternalURL(URI.create("https://alice.example.com/profile/card#me"));
    }
}
