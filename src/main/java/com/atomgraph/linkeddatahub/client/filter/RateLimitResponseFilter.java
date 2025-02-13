/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.filter;

import com.atomgraph.linkeddatahub.client.util.RateLimitTracker;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.client.ClientResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import static jakarta.ws.rs.core.Response.Status;
import java.io.IOException;
import java.net.URI;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RateLimitResponseFilter implements ClientResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(RateLimitResponseFilter.class);

    private final RateLimitTracker tracker;
    private final long defaultRetryAfter;

    public RateLimitResponseFilter(RateLimitTracker tracker, long defaultRetryAfter)
    {
        this.tracker = tracker;
        this.defaultRetryAfter = defaultRetryAfter;
    }

    @Override
    public void filter(ClientRequestContext requestContext, ClientResponseContext responseContext) throws IOException
    {
        if (responseContext.getStatusInfo().equals(Status.TOO_MANY_REQUESTS))
        {
            String retryAfter = responseContext.getHeaderString(HttpHeaders.RETRY_AFTER);
            long waitTime = parseRetryAfter(retryAfter);

            URI url = requestContext.getUri();
            getRateLimitTracker().registerRetryAfter(url, waitTime);

            if (log.isDebugEnabled()) log.debug("Rate limit detected for URL '{}', retry after {}ms", url, waitTime);
        }
    }

    private long parseRetryAfter(String retryAfter)
    {
        try
        {
            return Long.parseLong(retryAfter) * 1000L; // Convert seconds to milliseconds
        }
        catch (NumberFormatException e)
        {
            return this.defaultRetryAfter; // Default retry delay if Retry-After is missing or invalid
        }
    }
    
    public RateLimitTracker getRateLimitTracker()
    {
        return tracker;
    }
    
}
