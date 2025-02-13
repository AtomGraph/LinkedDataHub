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
package com.atomgraph.linkeddatahub.client.util;

import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RetryAfterHelper
{
    
    private static final Logger log = LoggerFactory.getLogger(RetryAfterHelper.class);

    private final long defaultDelayMillis;
    
    public RetryAfterHelper(long defaultDelayMillis)
    {
        this.defaultDelayMillis = defaultDelayMillis;
    }

    public Response execWithRetry(Supplier<Response> invocation)
    {
        while (true)
        {
            Response response = invocation.get();
            if (response.getStatusInfo().equals(Status.TOO_MANY_REQUESTS))
            {
                String retryAfterHeader = response.getHeaderString(HttpHeaders.RETRY_AFTER);
                long delayMillis = getDefaultDelayMillis();
                
                if (retryAfterHeader != null)
                {
                    try
                    {
                        delayMillis = Long.parseLong(retryAfterHeader) * 1000L;
                    }
                    catch (NumberFormatException ex)
                    {
                        // Fallback to default delay
                    }
                }
                
                if (log.isDebugEnabled()) log.debug("Received '429 Too Many Requests' response. Waiting {}ms before retrying.", delayMillis);
                response.close();
                
                try
                {
                    Thread.sleep(delayMillis);
                }
                catch (InterruptedException ie)
                {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Interrupted during retry delay", ie);
                }
                
                continue;
            }
            return response;
        }
    }
    
    public long getDefaultDelayMillis()
    {
        return defaultDelayMillis;
    }
    
}
