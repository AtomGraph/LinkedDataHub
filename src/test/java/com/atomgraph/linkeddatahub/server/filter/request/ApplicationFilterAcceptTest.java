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
package com.atomgraph.linkeddatahub.server.filter.request;

import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import java.net.URI;
import java.util.List;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.server.ContainerRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests that {@link ApplicationFilter#setAccept} copies a well-formed <code>accept</code> query parameter into the
 * <code>Accept</code> header, and refuses a malformed one with 400 before touching the header, which the
 * exception mapper that writes the 400 still has to read.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationFilterAcceptTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");

    private ApplicationFilter filter;
    private ContainerRequest request;

    @BeforeEach
    public void setUp()
    {
        filter = new ApplicationFilter();
        request = new ContainerRequest(BASE_URI, BASE_URI, "GET", null, new MapPropertiesDelegate(), null);
    }

    @Test
    public void wellFormedValueReplacesHeader()
    {
        request.header(HttpHeaders.ACCEPT, "text/html");

        filter.setAccept(request, "application/ld+json");

        assertEquals("application/ld+json", request.getHeaderString(HttpHeaders.ACCEPT));
        assertEquals(List.of(MediaType.valueOf("application/ld+json")), request.getAcceptableMediaTypes());
    }

    @Test
    public void unencodedPlusIsRefusedAndHeaderKept()
    {
        request.header(HttpHeaders.ACCEPT, "text/html");

        assertThrows(BadRequestException.class, () -> filter.setAccept(request, "application/ld json"));

        assertEquals("text/html", request.getHeaderString(HttpHeaders.ACCEPT));
        assertEquals(List.of(MediaType.TEXT_HTML_TYPE), request.getAcceptableMediaTypes()); // what the mapper's selectVariant() reads
    }

    @Test
    public void bareTokenIsRefused()
    {
        request.header(HttpHeaders.ACCEPT, "text/html");

        assertThrows(BadRequestException.class, () -> filter.setAccept(request, "foo"));

        assertEquals(List.of(MediaType.TEXT_HTML_TYPE), request.getAcceptableMediaTypes());
    }

    @Test
    public void absentHeaderStaysAbsentAfterRefusal()
    {
        assertThrows(BadRequestException.class, () -> filter.setAccept(request, "application/ld json"));

        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT));
        assertEquals(List.of(MediaType.WILDCARD_TYPE), request.getAcceptableMediaTypes());
    }

}
