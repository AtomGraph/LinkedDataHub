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

/**
 * Utility class to execute HTTP client requests with automatic retry handling
 * for "429 Too Many Requests" responses.
 * <p>
 * This helper repeatedly invokes a supplied HTTP request (via a {@code Supplier<Response>}).
 * If a response with HTTP status 429 is returned, the helper will wait for a delay,
 * determined by the value of the {@code Retry-After} header (or a default delay if missing or invalid),
 * and retry the request. If the maximum number of retries is exceeded, the helper either
 * returns the last received response or (alternatively) can throw an exception.
 * </p>
 * <p>
 * Example usage:
 * <pre>
 *     RetryAfterHelper helper = new RetryAfterHelper(5000L, 3);
 *     Response response = helper.invokeWithRetry(() -&gt; client.target(url).request().get());
 * </pre>
 * </p>
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public class RetryAfterHelper
{
    
    private static final Logger log = LoggerFactory.getLogger(RetryAfterHelper.class);

    private final long defaultDelayMillis;
    private final int maxRetryCount;
    
    public RetryAfterHelper(long defaultDelayMillis, int maxRetryCount)
    {
        this.defaultDelayMillis = defaultDelayMillis;
        this.maxRetryCount = maxRetryCount;
    }

    /**
     * Executes the given invocation. If a 429 Too Many Requests response is received,
     * it waits for the delay (as specified by the <code>Retry-After</code> header or default) and retries.
     * If the number of retries exceeds maxRetryCount, the response is returned.
     *
     * @param invocation a supplier returning a Response.
     * @return the successful Response.
     */
    public Response invokeWithRetry(Supplier<Response> invocation)
    {
        int retryCount = 0;
        
        while (true)
        {
            Response response = invocation.get();
            
            if (response.getStatusInfo().equals(Status.TOO_MANY_REQUESTS))
            {
                retryCount++;
                if (retryCount > getMaxRetryCount())
                {
                    if (log.isWarnEnabled()) 
                        log.warn("Maximum retry count of {} exceeded. Returning the last response.", getMaxRetryCount());
                    // Alternatively, you can throw an exception here:
                    // throw new RuntimeException("Maximum retry count exceeded for request");
                    return response;
                }
                
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
                
                if (log.isDebugEnabled()) log.debug("Received 429 Too Many Requests. Retry attempt {} of {}. Waiting {}ms before retrying.", retryCount, getMaxRetryCount(), delayMillis);
                
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
    
    /**
     * Returns default period the client waits before retrying the request
     * 
     * @return millisecond amount
     */
    public long getDefaultDelayMillis()
    {
        return defaultDelayMillis;
    }
    
    /**
     * Returns the maximum amount of request retries
     * 
     * @return max request retry count
     */
    public int getMaxRetryCount()
    {
        return maxRetryCount;
    }
    
}
