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

import jakarta.ws.rs.core.HttpHeaders;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.server.ContainerRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Tests that a malformed <code>Accept-Language</code> header is dropped and a well-formed one is left alone.
 *
 * The request is a real Jersey {@link ContainerRequest} rather than a mock, so what fails here is Jersey's own header
 * parser - the same code an exception mapper's <code>selectVariant()</code> runs - and the assertion after the filter
 * is that the very call which used to throw now succeeds.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AcceptLanguageFilterTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");

    /** the value seen in production: a duplicate q and a q on a q */
    private static final String MALFORMED = "en-IN,en;q=0.9,en;q=0.9;q=0.8";

    private AcceptLanguageFilter filter;
    private ContainerRequest request;

    @BeforeEach
    public void setUp()
    {
        filter = new AcceptLanguageFilter();
        request = new ContainerRequest(BASE_URI, BASE_URI, "GET", null, new MapPropertiesDelegate(), null);
    }

    @Test
    public void malformedHeaderIsDropped() throws IOException
    {
        request.header(HttpHeaders.ACCEPT_LANGUAGE, MALFORMED);

        filter.filter(request);

        assertNull(request.getHeaderString(HttpHeaders.ACCEPT_LANGUAGE));
        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT_LANGUAGE));
        assertEquals(List.of(new Locale("*")), request.getAcceptableLanguages()); // Jersey's wildcard default, and no longer a throw
    }

    @Test
    public void wellFormedHeaderIsKept() throws IOException
    {
        request.header(HttpHeaders.ACCEPT_LANGUAGE, "lt,en;q=0.9");

        filter.filter(request);

        assertEquals("lt,en;q=0.9", request.getHeaderString(HttpHeaders.ACCEPT_LANGUAGE));
        assertEquals(List.of(Locale.forLanguageTag("lt"), Locale.forLanguageTag("en")), request.getAcceptableLanguages());
    }

    @Test
    public void absentHeaderIsLeftAbsent() throws IOException
    {
        filter.filter(request);

        assertNull(request.getHeaderString(HttpHeaders.ACCEPT_LANGUAGE));
        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT_LANGUAGE));
    }

}
