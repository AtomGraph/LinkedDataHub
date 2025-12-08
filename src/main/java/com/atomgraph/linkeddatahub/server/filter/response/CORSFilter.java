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
package com.atomgraph.linkeddatahub.server.filter.response;

import jakarta.annotation.Priority;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;

/**
 * Response filter that adds CORS (Cross-Origin Resource Sharing) headers to allow cross-origin access.
 * Runs at HEADER_DECORATOR priority to ensure CORS headers are present on all responses including errors.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Provider
@Priority(Priorities.HEADER_DECORATOR)
public class CORSFilter implements ContainerResponseFilter
{
    private static final String ALLOWED_METHODS = String.join(", ",
        HttpMethod.GET,
        HttpMethod.POST,
        HttpMethod.PUT,
        HttpMethod.DELETE,
        HttpMethod.PATCH,
        HttpMethod.HEAD,
        HttpMethod.OPTIONS
    );

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response) throws IOException
    {
        if (request.getHeaderString("Origin") != null)
        {
            response.getHeaders().add("Access-Control-Allow-Origin", "*");
            response.getHeaders().add("Access-Control-Allow-Methods", ALLOWED_METHODS);
            response.getHeaders().add("Access-Control-Allow-Headers", "Accept, Content-Type, Authorization");
            response.getHeaders().add("Access-Control-Expose-Headers", "Link, Content-Location, Location");

            // Handle preflight OPTIONS requests
            if (HttpMethod.OPTIONS.equalsIgnoreCase(request.getMethod()))
            {
                response.setStatus(Response.Status.NO_CONTENT.getStatusCode());
                response.getHeaders().add("Access-Control-Max-Age", String.valueOf(getMaxAge()));
            }
        }
    }

    /**
     * Returns the maximum age (in seconds) for which browsers should cache the preflight response.
     *
     * @return max-age value in seconds (default: 1728000 = 20 days)
     */
    public int getMaxAge()
    {
        return 1728000; // 20 days
    }
}
