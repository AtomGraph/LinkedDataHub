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
package com.atomgraph.linkeddatahub.resource;

import jakarta.ws.rs.BadRequestException;
import org.junit.Test;

import java.net.URI;

/**
 * Unit tests for Transform SSRF protection.
 * Tests the validateNotInternalURL method to ensure it properly blocks access to internal addresses.
 *
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/253">LNK-002: SSRF primitives in admin endpoint</a>
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class TransformTest
{

    @Test(expected = IllegalArgumentException.class)
    public void testNullURI()
    {
        Transform.validateNotInternalURL(null);
    }

    @Test(expected = BadRequestException.class)
    public void testLinkLocalIPv4Blocked()
    {
        Transform.validateNotInternalURL(URI.create("http://169.254.1.1:8080/query.rq"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass10Blocked()
    {
        Transform.validateNotInternalURL(URI.create("http://10.0.0.1:8080/data.ttl"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass172Blocked()
    {
        Transform.validateNotInternalURL(URI.create("http://172.16.0.0:8080/query.rq"));
    }

    @Test(expected = BadRequestException.class)
    public void testPrivateClass192Blocked()
    {
        Transform.validateNotInternalURL(URI.create("http://192.168.1.1:8080/data.ttl"));
    }

    @Test
    public void testExternalURLAllowed()
    {
        // Public IPs should be allowed (no exception thrown)
        Transform.validateNotInternalURL(URI.create("http://8.8.8.8:80/query.rq"));
    }

    @Test
    public void testPublicDomainAllowed()
    {
        // Public domains should be allowed (no exception thrown)
        Transform.validateNotInternalURL(URI.create("http://example.org/data.ttl"));
    }

    @Test
    public void testHTTPSAllowed()
    {
        // HTTPS to public domain should be allowed (no exception thrown)
        Transform.validateNotInternalURL(URI.create("https://dbpedia.org/sparql"));
    }
}
