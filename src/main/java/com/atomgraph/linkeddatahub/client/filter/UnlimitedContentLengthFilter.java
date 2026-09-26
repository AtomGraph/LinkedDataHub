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

/**
 * Client request filter that exempts a request's response from the configured content length limit.
 * <p>
 * {@link ContentLengthLimitFilter} bounds what the Linked Data proxy and the imports pull in from
 * origins nobody controls. It is registered on the outbound clients as a whole, and those clients are
 * not split by trust: the same client that reads this deployment's own Graph Store also dereferences
 * remote WebID profiles. So the exemption is made per request rather than per client, which is what
 * keeps the guard on the untrusted fetches while taking it off this deployment's own store.
 * <p>
 * Without it a document whose graph serializes larger than the limit cannot be read at all: the write
 * that created it was never bounded, so a successful import could produce a representation the read
 * path refused for good.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 * @see ContentLengthLimitFilter#UNLIMITED
 */
public class UnlimitedContentLengthFilter implements ClientRequestFilter
{

    @Override
    public void filter(ClientRequestContext requestContext) throws IOException
    {
        requestContext.setProperty(ContentLengthLimitFilter.UNLIMITED, true);
    }

}
