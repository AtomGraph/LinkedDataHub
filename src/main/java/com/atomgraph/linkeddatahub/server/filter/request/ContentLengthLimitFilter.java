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

import com.atomgraph.linkeddatahub.server.util.stream.RejectTooLongInputStream;
import java.io.IOException;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response.Status;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
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
            crc.setEntityStream(new RejectTooLongInputStream(crc.getEntityStream(), getSystem().getMaxContentLength()));
            return;
        }
        
        int contentLength = Integer.valueOf(contentLengthString);
        if (contentLength > getSystem().getMaxContentLength())
        {
            if (log.isDebugEnabled()) log.debug("POST or PUT request rejected due to Content-Length: {} which is larger than the configured limit {}", contentLength, getSystem().getMaxContentLength());
            throw new WebApplicationException(Status.REQUEST_ENTITY_TOO_LARGE);
        }
        
        crc.setEntityStream(new RejectTooLongInputStream(crc.getEntityStream(), getSystem().getMaxContentLength()));
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
