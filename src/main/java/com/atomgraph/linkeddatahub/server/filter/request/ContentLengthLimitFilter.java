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
    private final int maxContentLength;
    
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
            if (log.isDebugEnabled()) log.debug("POST or PUT request rejected due to Content-Length: {} which is larger than the configured limit {}", contentLength, getMaxContentLength());
            throw new RequestContentTooLargeException(getMaxContentLength(), contentLength);
        }
        
        responseContext.setEntityStream(new RejectTooLargeResponseInputStream(responseContext.getEntityStream(), getMaxContentLength()));
    }

    public int getMaxContentLength()
    {
        return maxContentLength;
    }
    
}
