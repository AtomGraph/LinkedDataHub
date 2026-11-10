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

import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import jakarta.annotation.Priority;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Optional;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Rejects state-changing requests that a browser sends from another origin.
 * The browser presents the agent's client certificate at the TLS level, and <code>SameSite</code> does not govern it,
 * so a page on any site could otherwise submit a form (<code>multipart/form-data</code>,
 * <code>application/x-www-form-urlencoded</code>) that writes as the agent.
 * The client's own cross-origin requests go through the <code>?uri=</code> proxy on the page origin, so they arrive same-origin.
 * Requests without an <code>Origin</code> header (the CLI, Web-Algebra, server-side clients) are not browser requests and pass.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(750) // after ApplicationFilter (700), which resolves the dataspace whose origin this compares against
public class OriginFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(OriginFilter.class);

    /** Request header that names the origin of a browser request (RFC 6454 §7) */
    public static final String ORIGIN = "Origin";

    /** Methods that do not change state (RFC 9110 §9.2.1) */
    public static final Set<String> SAFE_METHODS = Set.of(HttpMethod.GET, HttpMethod.HEAD, HttpMethod.OPTIONS, "TRACE");

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (SAFE_METHODS.contains(request.getMethod())) return;

        String origin = request.getHeaderString(ORIGIN);
        if (origin == null) return;

        Optional<Dataspace> dataspace = (Optional<Dataspace>)request.getProperty(LDS.Dataspace.getURI());
        if (dataspace == null || dataspace.isEmpty()) return; // ApplicationFilter has already answered 404

        if (!isSameOrigin(origin, dataspace.get().getOriginURI()))
        {
            if (log.isDebugEnabled()) log.debug("{} request from origin '{}' rejected by dataspace origin <{}>", request.getMethod(), origin, dataspace.get().getOriginURI());
            throw new ForbiddenException("Origin '" + origin + "' cannot make " + request.getMethod() + " requests to this dataspace");
        }
    }

    /**
     * Returns true if the <code>Origin</code> header value names the given dataspace origin.
     * An opaque origin (<code>null</code>) and an unparseable value name no origin.
     *
     * @param origin <code>Origin</code> header value
     * @param dataspaceOrigin origin URI of the dataspace
     * @return true if same origin
     */
    public static boolean isSameOrigin(String origin, URI dataspaceOrigin)
    {
        try
        {
            return new URI(origin).equals(dataspaceOrigin); // scheme and host compare case-insensitively
        }
        catch (URISyntaxException ex)
        {
            return false;
        }
    }

}
