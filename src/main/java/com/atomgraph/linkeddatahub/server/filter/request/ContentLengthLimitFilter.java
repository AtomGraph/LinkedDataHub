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

import com.atomgraph.linkeddatahub.server.exception.PayloadTooLargeException;
import com.atomgraph.linkeddatahub.server.util.stream.RejectTooLargeInputStream;
import java.io.IOException;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
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
public class ContentLengthLimitFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ContentLengthLimitFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;

    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        if (getSystem().getMaxContentLength() == null) return; // skip the filter if max Content-Length limit is not configured
        if (!(crc.getMethod().equals(HttpMethod.POST) || crc.getMethod().equals(HttpMethod.PUT))) return; // only check Content-Length on POST and PUT requests
            
        String contentLengthString = crc.getHeaders().getFirst(HttpHeaders.CONTENT_LENGTH);
        // we cannot abort here with Status.LENGTH_REQUIRED if we want to allow streaming. That is the job of RejectTooLongInputStream
        if (contentLengthString == null)
        {
            crc.setEntityStream(new RejectTooLargeInputStream(crc.getEntityStream(), getSystem().getMaxContentLength()));
            return;
        }
        
        int contentLength = Integer.valueOf(contentLengthString);
        if (contentLength > getSystem().getMaxContentLength())
        {
            if (log.isDebugEnabled()) log.debug("POST or PUT request rejected due to Content-Length: {} which is larger than the configured limit {}", contentLength, getSystem().getMaxContentLength());
            throw new PayloadTooLargeException(getSystem().getMaxContentLength(), contentLength);
        }
        
        crc.setEntityStream(new RejectTooLargeInputStream(crc.getEntityStream(), getSystem().getMaxContentLength()));
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
