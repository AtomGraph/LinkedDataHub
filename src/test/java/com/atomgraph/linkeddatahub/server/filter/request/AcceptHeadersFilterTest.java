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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Variant;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.server.ContainerRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Tests that a malformed content negotiation header is dropped and a well-formed one is left alone.
 *
 * The request is a real Jersey {@link ContainerRequest} rather than a mock, so what fails here is Jersey's own header
 * parser, and the assertion after the filter is that <code>selectVariant()</code> - the call an exception mapper makes,
 * which used to throw - now succeeds.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AcceptHeadersFilterTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final List<Variant> VARIANTS = Variant.mediaTypes(MediaType.TEXT_HTML_TYPE).languages(Locale.ENGLISH).build();

    private AcceptHeadersFilter filter;
    private ContainerRequest request;

    @BeforeEach
    public void setUp()
    {
        filter = new AcceptHeadersFilter();
        request = new ContainerRequest(BASE_URI, BASE_URI, "GET", null, new MapPropertiesDelegate(), null);
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
        "Accept          | application/ld json",            // seen in production: the + of application/ld+json decoded to a space
        "Accept-Language | en-IN,en;q=0.9,en;q=0.9;q=0.8",  // seen in production: a duplicate q and a q on a q
        "Accept-Charset  | utf-8;q=x",
        "Accept-Encoding | gzip;q=x"
    })
    public void malformedHeaderIsDropped(String header, String value) throws IOException
    {
        request.header(header, value);

        filter.filter(request);

        assertNull(request.getHeaderString(header));
        assertFalse(request.getHeaders().containsKey(header));
        assertNotNull(request.selectVariant(VARIANTS)); // no longer a throw
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
        "Accept          | text/turtle,application/ld+json",
        "Accept-Language | lt,en;q=0.9",
        "Accept-Charset  | utf-8,iso-8859-1;q=0.5",
        "Accept-Encoding | gzip,deflate;q=0.5"
    })
    public void wellFormedHeaderIsKept(String header, String value) throws IOException
    {
        request.header(header, value);

        filter.filter(request);

        assertEquals(value, request.getHeaderString(header));
    }

    @Test
    public void onlyTheMalformedHeaderIsDropped() throws IOException
    {
        request.header(HttpHeaders.ACCEPT, "application/ld json");
        request.header(HttpHeaders.ACCEPT_LANGUAGE, "lt,en;q=0.9");

        filter.filter(request);

        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT));
        assertEquals(List.of(MediaType.WILDCARD_TYPE), request.getAcceptableMediaTypes()); // Jersey's wildcard default
        assertEquals(List.of(Locale.forLanguageTag("lt"), Locale.forLanguageTag("en")), request.getAcceptableLanguages());
    }

    @Test
    public void absentHeadersAreLeftAbsent() throws IOException
    {
        filter.filter(request);

        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT));
        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT_LANGUAGE));
        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT_CHARSET));
        assertFalse(request.getHeaders().containsKey(HttpHeaders.ACCEPT_ENCODING));
    }

}
