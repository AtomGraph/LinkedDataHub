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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Variant;
import java.math.BigInteger;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * The rendering key goes into the entity tag of the rendered variants only.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RenderedResponseTest
{

    private static final EntityTag TAG = new EntityTag("0123456789abcdef");

    private RenderedResponse response(MediaType selected, String key, AtomicInteger asked)
    {
        Request request = mock(Request.class);
        when(request.selectVariant(anyList())).thenReturn(new Variant(selected, (Locale)null, null));

        return new RenderedResponse(request, mock(HttpHeaders.class), "entity", null, TAG,
            List.of(MediaType.TEXT_HTML_TYPE, MediaType.valueOf("text/turtle")), List.of(), List.of(),
            new HTMLMediaTypePredicate(), List.of(), new HTMLMediaTypePredicate(),
            () -> { asked.incrementAndGet(); return key; });
    }

    @Test
    public void testRenderedVariantTagChangesWithKey()
    {
        EntityTag before = response(MediaType.TEXT_HTML_TYPE, "stylesheet\npackage-a", new AtomicInteger()).getVariantEntityTag();
        EntityTag after = response(MediaType.TEXT_HTML_TYPE, "stylesheet\npackage-a\npackage-b", new AtomicInteger()).getVariantEntityTag();
        EntityTag again = response(MediaType.TEXT_HTML_TYPE, "stylesheet\npackage-a", new AtomicInteger()).getVariantEntityTag();

        assertNotEquals(before, after); // a package added changes the HTML, and so its tag
        assertEquals(before, again);
        new BigInteger(before.getValue(), 16); // still hex: the XSLT writers add the agent to it as a number
    }

    @Test
    public void testDataVariantTagIgnoresKey()
    {
        AtomicInteger asked = new AtomicInteger();
        EntityTag one = response(MediaType.valueOf("text/turtle"), "stylesheet", asked).getVariantEntityTag();
        EntityTag other = response(MediaType.valueOf("text/turtle"), "other stylesheet", asked).getVariantEntityTag();

        assertEquals(one, other);
        assertEquals(0, asked.get()); // the key is not computed for a representation it does not affect
    }

    @Test
    public void testNoKeyKeepsTag()
    {
        RenderedResponse response = response(MediaType.TEXT_HTML_TYPE, null, new AtomicInteger());
        assertEquals(new com.atomgraph.core.model.impl.Response(mock(Request.class), mock(HttpHeaders.class), "entity", null, TAG, response.getVariant(), new HTMLMediaTypePredicate()).getVariantEntityTag(),
            response.getVariantEntityTag());
    }

}
