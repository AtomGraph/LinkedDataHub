/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.client.exception.ResponseContentTooLargeException;
import com.atomgraph.linkeddatahub.client.util.RejectTooLargeResponseInputStream;
import com.atomgraph.linkeddatahub.server.exception.RequestContentTooLargeException;
import com.atomgraph.linkeddatahub.server.util.RejectTooLargeRequestInputStream;
import java.io.IOException;
import jakarta.annotation.Priority;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.client.ClientResponseFilter;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.HttpHeaders;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Content length limiting request filter.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(100) // the very first request filter
public class ContentLengthLimitFilter implements ContainerRequestFilter, ClientResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(ContentLengthLimitFilter.class);

    /** Request property that exempts the response of a single client request from the limit */
    public static final String UNLIMITED = ContentLengthLimitFilter.class.getName() + ".unlimited";

    private final int maxContentLength;
    
    /**
     * Constructs content length limit filter.
     * 
     * @param maxContentLength maximum content length
     */
    public ContentLengthLimitFilter(int maxContentLength)
    {
        this.maxContentLength = maxContentLength;
    }

    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        if (!crc.hasEntity()) return;
            
        String contentLengthString = crc.getHeaders().getFirst(HttpHeaders.CONTENT_LENGTH);
        // we cannot abort here with Status.LENGTH_REQUIRED if we want to allow streaming. That is the job of RejectTooLongInputStream
        if (contentLengthString == null)
        {
            crc.setEntityStream(new RejectTooLargeRequestInputStream(crc.getEntityStream(), getMaxContentLength()));
            return;
        }
        
        int contentLength = Integer.parseInt(contentLengthString);
        if (contentLength > getMaxContentLength())
        {
            if (log.isDebugEnabled()) log.debug("POST or PUT request rejected due to Content-Length: {} which is larger than the configured limit {}", contentLength, getMaxContentLength());
            throw new RequestContentTooLargeException(getMaxContentLength(), contentLength);
        }
        
        crc.setEntityStream(new RejectTooLargeRequestInputStream(crc.getEntityStream(), getMaxContentLength()));
    }

    @Override
    public void filter(ClientRequestContext requestContext, ClientResponseContext responseContext) throws IOException
    {
        // the limit bounds untrusted content the proxy and the imports pull in; a configured internal
        // service whose payload is large by design opts out per request instead of widening it for all
        if (Boolean.TRUE.equals(requestContext.getProperty(UNLIMITED))) return;

        if (!responseContext.hasEntity()) return;
        
        String contentLengthString = responseContext.getHeaders().getFirst(HttpHeaders.CONTENT_LENGTH);
        // we cannot abort here with Status.LENGTH_REQUIRED if we want to allow streaming. That is the job of RejectTooLongInputStream
        if (contentLengthString == null)
        {
            responseContext.setEntityStream(new RejectTooLargeResponseInputStream(responseContext.getEntityStream(), getMaxContentLength()));
            return;
        }
        
        int contentLength = Integer.parseInt(contentLengthString);
        if (contentLength > getMaxContentLength())
        {
            // ResponseContentTooLargeException (502), not RequestContentTooLargeException (413): what was too
            // large is the upstream's response, and 413 states that the caller's request body was - false on a
            // GET that carries none. The streaming branch above already throws this, so a response with a
            // Content-Length and the same response chunked no longer answer with different statuses
            if (log.isDebugEnabled()) log.debug("Response rejected due to Content-Length: {} which is larger than the configured limit {}", contentLength, getMaxContentLength());
            throw new ResponseContentTooLargeException(getMaxContentLength(), contentLength);
        }

        responseContext.setEntityStream(new RejectTooLargeResponseInputStream(responseContext.getEntityStream(), getMaxContentLength()));
    }

    /**
     * Returns the maximum content length.
     * 
     * @return maximum content length in bytes
     */
    public int getMaxContentLength()
    {
        return maxContentLength;
    }
    
}
