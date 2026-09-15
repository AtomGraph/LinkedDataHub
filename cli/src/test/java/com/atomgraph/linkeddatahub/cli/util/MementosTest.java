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

package com.atomgraph.linkeddatahub.cli.util;

import java.net.URI;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests the addressing of the Memento roles and the <code>Accept-Datetime</code> format.
 */
public class MementosTest
{

    static final URI DOC = URI.create("https://localhost:4443/some/");

    @Test
    public void mementoRolesAreQueryParamsOnTheDocumentURI()
    {
        assertEquals(URI.create("https://localhost:4443/some/?version=a1b2c3"), Mementos.version(DOC, "a1b2c3"));
        assertEquals(URI.create("https://localhost:4443/some/?timemap"), Mementos.timeMap(DOC));
        assertEquals(URI.create("https://localhost:4443/some/?timegate"), Mementos.timeGate(DOC));
    }

    @Test
    public void valuelessParamsKeepTheBareFormTheServerAdvertises()
    {
        // the Link headers point at <doc?timemap>, not <doc?timemap=>
        assertEquals("timemap", Mementos.timeMap(DOC).getRawQuery());
        assertEquals("timegate", Mementos.timeGate(DOC).getRawQuery());
    }

    @Test
    public void anExistingQueryIsKeptAndTheFragmentStaysLast()
    {
        assertEquals(URI.create("https://localhost:4443/some/?a=b&timemap"), Mementos.timeMap(URI.create("https://localhost:4443/some/?a=b")));
        assertEquals(URI.create("https://localhost:4443/some/?version=a1b2c3#this"), Mementos.version(URI.create("https://localhost:4443/some/#this"), "a1b2c3"));
    }

    @Test
    public void acceptDatetimeTakesRFC1123AndISO8601()
    {
        assertEquals("Thu, 20 Aug 2026 10:00:00 GMT", Mementos.acceptDatetime("Thu, 20 Aug 2026 10:00:00 GMT"));
        assertEquals("Thu, 20 Aug 2026 10:00:00 GMT", Mementos.acceptDatetime("2026-08-20T10:00:00Z"));
        assertEquals("Thu, 20 Aug 2026 10:00:00 GMT", Mementos.acceptDatetime("2026-08-20T12:00:00+02:00"));
    }

    @Test
    public void theDayOfMonthIsZeroPadded()
    {
        // RFC_1123_DATE_TIME leaves it unpadded where the RFC 7089 grammar wants 2DIGIT
        assertEquals("Wed, 05 Aug 2026 10:00:00 GMT", Mementos.acceptDatetime("2026-08-05T10:00:00Z"));
    }

    @Test
    public void anUnparseableDatetimeIsRejected()
    {
        assertThrows(IllegalArgumentException.class, () -> Mementos.acceptDatetime("yesterday afternoon"));
    }

}
