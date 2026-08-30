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

package com.atomgraph.linkeddatahub.cli.http;

import com.atomgraph.core.MediaTypes;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the <code>curl -f</code> equivalent: error statuses become exceptions, success statuses
 * pass through. Driven against {@link StubServer} so the responses are real inbound ones - an
 * outbound {@code Response} built in-process cannot be read back.
 */
public class HttpExceptionTest
{

    private static final MediaType[] ACCEPT_TURTLE = { com.atomgraph.core.MediaType.TEXT_TURTLE_TYPE };

    static LDHClient client() throws Exception
    {
        return new LDHClient(ClientFactory.createClient(ClientFactoryTest.keyStorePath(), "changeit"), new MediaTypes(), null);
    }

    @Test
    public void passesThroughSuccessStatus() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(200, "<https://localhost:4443/> a <https://www.w3.org/ns/ldt/document-hierarchy#Container> .");
            URI target = server.baseURI().resolve("some/");

            try (Response response = HttpException.check(target, client().get(target, ACCEPT_TURTLE)))
            {
                assertEquals(200, response.getStatus());
            }
        }
    }

    @Test
    public void passesThroughNoContent() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(204, "");
            URI target = server.baseURI().resolve("some/");

            try (Response response = HttpException.check(target, client().get(target, ACCEPT_TURTLE)))
            {
                assertEquals(204, response.getStatus());
            }
        }
    }

    @Test
    public void throwsOnErrorStatusCarryingStatusAndURI() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(403, "");
            URI target = server.baseURI().resolve("some/");

            HttpException e = assertThrows(HttpException.class, () -> HttpException.check(target, client().get(target, ACCEPT_TURTLE)));

            assertEquals(403, e.getStatus());
            assertEquals(target, e.getUri());
            assertTrue(e.getMessage().startsWith("HTTP 403 Forbidden"), e.getMessage());
            assertTrue(e.getMessage().contains(target.toString()), e.getMessage());
        }
    }

    @Test
    public void errorMessageCarriesBodyExcerpt() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(422, "Constraint violation on dct:title");
            URI target = server.baseURI().resolve("some/");

            HttpException e = assertThrows(HttpException.class, () -> HttpException.check(target, client().get(target, ACCEPT_TURTLE)));

            assertEquals(422, e.getStatus());
            assertTrue(e.getMessage().endsWith("\nConstraint violation on dct:title"), e.getMessage());
        }
    }

    @Test
    public void longErrorBodyIsTruncated() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(500, "x".repeat(2000));
            URI target = server.baseURI().resolve("some/");

            HttpException e = assertThrows(HttpException.class, () -> HttpException.check(target, client().get(target, ACCEPT_TURTLE)));

            assertTrue(e.getMessage().endsWith("…"), "excerpt is not marked as truncated");
            assertTrue(e.getMessage().contains("x".repeat(1024)), "excerpt is shorter than the limit");
            assertFalse(e.getMessage().contains("x".repeat(1025)), "excerpt exceeds the limit");
        }
    }

}
