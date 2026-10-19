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
package com.atomgraph.linkeddatahub.client.filter;

import com.atomgraph.linkeddatahub.server.filter.request.ContentLengthLimitFilter;
import java.io.IOException;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.client.ClientResponseFilter;

/**
 * Client filter that bounds a request's response with a limit of its own, in place of the configured one.
 * <p>
 * The configured limit ({@link ContentLengthLimitFilter}) bounds content from origins nobody controls, and
 * this deployment's own store is exempt from it ({@link UnlimitedContentLengthFilter}). A query result
 * answered to an HTTP caller of the SPARQL endpoint is bounded for a different reason: the endpoint
 * buffers it whole, and so does whatever receives it - a page renders it in the browser's only thread.
 * That bound is not the configured one, which is a limit on input. So the request carries its own,
 * which the configured filter on the same client honours, and this filter applies it itself for a
 * client without one.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 * @see ContentLengthLimitFilter#MAX_CONTENT_LENGTH
 */
public class ResponseLengthLimitFilter implements ClientRequestFilter, ClientResponseFilter
{

    private final ContentLengthLimitFilter limitFilter;

    /**
     * Constructs filter.
     *
     * @param maxContentLength maximum response length in bytes
     */
    public ResponseLengthLimitFilter(int maxContentLength)
    {
        this.limitFilter = new ContentLengthLimitFilter(maxContentLength);
    }

    @Override
    public void filter(ClientRequestContext requestContext) throws IOException
    {
        requestContext.setProperty(ContentLengthLimitFilter.MAX_CONTENT_LENGTH, getLimitFilter().getMaxContentLength());
    }

    @Override
    public void filter(ClientRequestContext requestContext, ClientResponseContext responseContext) throws IOException
    {
        getLimitFilter().filter(requestContext, responseContext);
    }

    /**
     * Returns the filter that applies the limit.
     *
     * @return content length limit filter
     */
    public ContentLengthLimitFilter getLimitFilter()
    {
        return limitFilter;
    }

}
