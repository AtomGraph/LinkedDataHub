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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.server.exception.RequestContentTooLargeException;
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
 * Unit tests for {@link RejectTooLargeRequestInputStream}.
 * <p>
 * This is the half of the inbound guard that does the work. A request that declares its size is
 * refused by the {@code Content-Length} check in
 * {@link com.atomgraph.linkeddatahub.server.filter.request.ContentLengthLimitFilter} before the body
 * is touched, but a chunked request declares nothing, so only counting the bytes as they are read
 * can stop it - and the filter wraps the stream even after a passing header check, so a
 * {@code Content-Length} that understates the body is caught here too.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RejectTooLargeRequestInputStreamTest
{

    private static final int LIMIT = 16;

    private static InputStream stream(int bytes, long limit)
    {
        return new RejectTooLargeRequestInputStream(new ByteArrayInputStream(new byte[bytes]), limit);
    }

    /** The limit is a maximum, not a strict bound: exactly that many bytes is a request that fits. */
    @Test
    public void testBodyAtTheLimitIsReadWhole() throws IOException
    {
        byte[] body = "0123456789abcdef".getBytes(StandardCharsets.UTF_8); // exactly LIMIT bytes
        InputStream in = new RejectTooLargeRequestInputStream(new ByteArrayInputStream(body), LIMIT);

        assertArrayEquals(body, in.readAllBytes());
    }

    /** One byte past the limit, read one byte at a time. */
    @Test
    public void testBodyOverTheLimitRaisesOnSingleByteRead()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        assertThrows(RequestContentTooLargeException.class, () ->
        {
            for (int i = 0; i <= LIMIT; i++) in.read();
        });
    }

    /**
     * The same body read in bulk. Both overloads count, and this is the one Jersey uses for an
     * entity stream, so a guard that only counted single-byte reads would never fire in production.
     */
    @Test
    public void testBodyOverTheLimitRaisesOnBulkRead()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        assertThrows(RequestContentTooLargeException.class, () -> in.readAllBytes());
    }

    /** 413, because what was too large is the caller's request body. The response half answers 502. */
    @Test
    public void testRaisesRequestEntityTooLarge()
    {
        InputStream in = stream(LIMIT + 1, LIMIT);

        RequestContentTooLargeException e = assertThrows(RequestContentTooLargeException.class, () -> in.readAllBytes());
        assertEquals(Response.Status.REQUEST_ENTITY_TOO_LARGE.getStatusCode(), e.getResponse().getStatus());
    }

}
