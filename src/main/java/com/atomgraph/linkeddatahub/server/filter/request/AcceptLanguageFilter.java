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
package com.atomgraph.linkeddatahub.server.filter.request;

import jakarta.annotation.Priority;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.HttpHeaders;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Drops an <code>Accept-Language</code> header that does not parse, so the request proceeds as if the client stated
 * no language preference.
 *
 * The header is advisory, so a malformed value is no reason to refuse the request. It is also not something a later
 * stage can recover from: JAX-RS parses it lazily, on every <code>Request.selectVariant()</code> and
 * <code>getAcceptableLanguages()</code> call, and every exception mapper's response is built through
 * <code>selectVariant()</code>. A parse failure raised inside a mapper escapes it, and what the client gets is the
 * container's 500 in place of the status the mapper meant to send - a 403 for an unauthorized request, say. The
 * header is read from the request's live header map each time, so removing it here, before any filter that can
 * throw into a mapper, is what makes every later reader see a request with no preference instead.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(200) // before ApplicationFilter (700) and anything else that can fail into an exception mapper; after ContentLengthLimitFilter (100)
public class AcceptLanguageFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(AcceptLanguageFilter.class);

    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        try
        {
            crc.getAcceptableLanguages();
        }
        catch (ProcessingException ex) // Jersey's HeaderValueException, caught by its JAX-RS supertype so no internal class is named
        {
            if (log.isDebugEnabled()) log.debug("Ignoring malformed Accept-Language header value: '{}'", crc.getHeaderString(HttpHeaders.ACCEPT_LANGUAGE));
            crc.getHeaders().remove(HttpHeaders.ACCEPT_LANGUAGE);
        }
    }

}
