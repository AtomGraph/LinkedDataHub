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
package com.atomgraph.linkeddatahub.client.util;

import com.atomgraph.linkeddatahub.client.exception.ResponseContentTooLargeException;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Unit tests for {@link RejectTooLargeResponseInputStream}.
 * <p>
 * The mirror of {@link com.atomgraph.linkeddatahub.server.util.RejectTooLargeRequestInputStream}:
 * same base class, differing only in which exception {@code raiseError} throws. It bounds what the
 * Linked Data proxy and the imports pull in from origins nobody controls, and it is the half that
 * fires when the upstream sends no {@code Content-Length} - a chunked response declares nothing, so
 * only counting the bytes can stop it.
 * <p>
 * This stream has always answered {@code 502}. The {@code Content-Length} branch of
 * {@link com.atomgraph.linkeddatahub.server.filter.request.ContentLengthLimitFilter} answered
 * {@code 413} until 6.0.0, so the same upstream response answered with a different status depending
 * only on whether it declared its size; the branch was corrected to agree with this.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RejectTooLargeResponseInputStreamTest
{

    private static final int LIMIT = 16;

    private static InputStream stream(int bytes, long limit)
    {
        return new RejectTooLargeResponseInputStream(new ByteArrayInputStream(new byte[bytes]), limit);
    }

    /** The limit is a maximum, not a strict bound: exactly that many bytes is a response that fits. */
    @Test
    public void testBodyAtTheLimitIsReadWhole() throws IOException
    {
        byte[] body = "0123456789abcdef".getBytes(StandardCharsets.UTF_8); // exactly LIMIT bytes
        InputStream in = new RejectTooLargeResponseInputStream(new ByteArrayInputStream(body), LIMIT);

        assertArrayEquals(body, in.readAllBytes());
    }

    /** One byte past the limit, read one byte at a time. */
    @Test
    public void testBodyOverTheLimitRaisesOnSingleByteRead()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        assertThrows(ResponseContentTooLargeException.class, () ->
        {
            for (int i = 0; i <= LIMIT; i++) in.read();
        });
    }

    /**
     * The same body read in bulk. Both overloads count, and this is the one an entity is read
     * through, so a guard that only counted single-byte reads would never fire in production.
     */
    @Test
    public void testBodyOverTheLimitRaisesOnBulkRead()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        assertThrows(ResponseContentTooLargeException.class, () -> in.readAllBytes());
    }

    /**
     * 502, not 413: what was too large is the upstream's response, and 413 would state that the
     * caller's own request body was.
     */
    @Test
    public void testRaisesBadGateway()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        ResponseContentTooLargeException e = assertThrows(ResponseContentTooLargeException.class, () -> in.readAllBytes());
        assertEquals(Response.Status.BAD_GATEWAY.getStatusCode(), e.getResponse().getStatus());
    }

}
