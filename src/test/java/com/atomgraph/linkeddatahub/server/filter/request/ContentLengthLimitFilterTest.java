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

import com.atomgraph.linkeddatahub.client.util.RejectTooLargeResponseInputStream;
import com.atomgraph.linkeddatahub.server.exception.RequestContentTooLargeException;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link ContentLengthLimitFilter}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class ContentLengthLimitFilterTest
{

    private static final int MAX_CONTENT_LENGTH = 1024;

    @Mock private ClientRequestContext requestContext;
    @Mock private ClientResponseContext responseContext;

    private ContentLengthLimitFilter filter;

    @BeforeEach
    public void setUp()
    {
        filter = new ContentLengthLimitFilter(MAX_CONTENT_LENGTH);
    }

    /** No Content-Length to check against — the response is read through the counting stream instead. */
    @Test
    public void testUnknownLengthResponseIsCounted() throws IOException
    {
        when(responseContext.hasEntity()).thenReturn(true);
        when(responseContext.getHeaders()).thenReturn(new MultivaluedHashMap<>());
        when(responseContext.getEntityStream()).thenReturn(new ByteArrayInputStream("data".getBytes(StandardCharsets.UTF_8)));

        filter.filter(requestContext, responseContext);

        verify(responseContext).setEntityStream(isA(RejectTooLargeResponseInputStream.class));
    }

    /** A Content-Length beyond the limit is rejected without reading the response at all. */
    @Test
    public void testOversizeResponseIsRejected()
    {
        MultivaluedMap<String, String> headers = new MultivaluedHashMap<>();
        headers.putSingle(HttpHeaders.CONTENT_LENGTH, String.valueOf(MAX_CONTENT_LENGTH + 1));
        when(responseContext.hasEntity()).thenReturn(true);
        when(responseContext.getHeaders()).thenReturn(headers);

        assertThrows(RequestContentTooLargeException.class, () -> filter.filter(requestContext, responseContext));
    }

    /**
     * A request that opted out is not limited: the SEF compiler's response is ~18 MiB by design,
     * far past the limit that bounds what the proxy and the imports pull in.
     */
    @Test
    public void testUnlimitedRequestSkipsLimit() throws IOException
    {
        when(requestContext.getProperty(ContentLengthLimitFilter.UNLIMITED)).thenReturn(true);

        filter.filter(requestContext, responseContext);

        verifyNoInteractions(responseContext);
    }

}
