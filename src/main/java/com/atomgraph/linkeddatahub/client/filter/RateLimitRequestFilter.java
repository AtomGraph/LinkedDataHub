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
import jakarta.ws.rs.client.ClientRequestFilter;
import java.io.IOException;
import java.net.URI;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RateLimitRequestFilter implements ClientRequestFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(RateLimitRequestFilter.class);

    private final RateLimitTracker tracker;

    public RateLimitRequestFilter(RateLimitTracker tracker)
    {
        this.tracker = tracker;
    }

    @Override
    public void filter(ClientRequestContext requestContext) throws IOException
    {
        URI url = requestContext.getUri();
        Long retryTime = getRateLimitTracker().getRetryTime(url);

        if (retryTime != null)
        {
            long remainingWait = retryTime - System.currentTimeMillis();
            if (remainingWait > 0)
            {
                if (log.isDebugEnabled()) log.debug("Waiting {}ms before retrying request to URL: {}", remainingWait, url);
                
                try
                {
                    TimeUnit.MILLISECONDS.sleep(remainingWait);
                }
                catch (InterruptedException e)
                {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }
    
    public RateLimitTracker getRateLimitTracker()
    {
        return tracker;
    }
    
}
