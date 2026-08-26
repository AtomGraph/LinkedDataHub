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
 * Tests for {@link URIRewriter}.
 */
public class URIRewriterTest
{

    @Test
    public void rewriteReplacesOriginKeepingPathQueryFragment()
    {
        assertEquals(URI.create("https://localhost:8443/a%20b/c/?d=e#f"),
            URIRewriter.rewrite(URI.create("https://linkeddatahub.com/a%20b/c/?d=e#f"), URI.create("https://localhost:8443")));
    }

    @Test
    public void rewriteIgnoresProxyPath()
    {
        assertEquals(URI.create("https://localhost:8443/some/"),
            URIRewriter.rewrite(URI.create("https://linkeddatahub.com:4443/some/"), URI.create("https://localhost:8443/ignored/")));
    }

    @Test
    public void rewriteRejectsRelativeURI()
    {
        assertThrows(IllegalArgumentException.class,
            () -> URIRewriter.rewrite(URI.create("/relative/path"), URI.create("https://localhost:8443")));
    }

    @Test
    public void adminBasePrefixesHostWithAdminSubdomain()
    {
        assertEquals(URI.create("https://admin.localhost:4443/"), URIRewriter.adminBase(URI.create("https://localhost:4443/")));
    }

    @Test
    public void encodeSlugKeepsUnreservedCharacters()
    {
        assertEquals("abc-._~123", URIRewriter.encodeSlug("abc-._~123"));
    }

    @Test
    public void encodeSlugEncodesReservedAndNonASCII()
    {
        assertEquals("a%20b%2F%C4%87", URIRewriter.encodeSlug("a b/ć"));
    }

    @Test
    public void childURIAppendsEncodedSlugAndSlash()
    {
        assertEquals(URI.create("https://localhost:4443/some/my%20item/"),
            URIRewriter.childURI(URI.create("https://localhost:4443/some/"), "my item"));
    }

}
