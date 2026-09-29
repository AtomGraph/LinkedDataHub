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

package com.atomgraph.linkeddatahub.rdf;

import java.net.URI;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Tests for {@link URIs}.
 */
public class URIsTest
{

    @Test
    public void adminBasePrefixesHostWithAdminSubdomain()
    {
        assertEquals(URI.create("https://admin.localhost:4443/"), URIs.adminBase(URI.create("https://localhost:4443/")));
    }

    @Test
    public void encodeSlugKeepsUnreservedCharacters()
    {
        assertEquals("abc-._~123", URIs.encodeSlug("abc-._~123"));
    }

    @Test
    public void encodeSlugEncodesReservedAndNonASCII()
    {
        assertEquals("a%20b%2F%C4%87", URIs.encodeSlug("a b/ć"));
    }

    @Test
    public void childURIAppendsEncodedSlugAndSlash()
    {
        assertEquals(URI.create("https://localhost:4443/some/my%20item/"),
            URIs.childURI(URI.create("https://localhost:4443/some/"), "my item"));
    }

}
