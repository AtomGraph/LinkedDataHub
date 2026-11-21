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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Validator for URLs when loading data from external sources.
 * Prevents SSRF (Server-Side Request Forgery) attacks by validating that URLs
 * don't resolve to internal/private network addresses.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/252">LNK-004: SSRF primitive via On-Behalf-Of header</a>
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/253">LNK-002: SSRF primitives in admin endpoint</a>
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/287">LNK-009: SSRF via proxy URI parameter</a>
 */
public class URLValidator
{
    private static final Logger log = LoggerFactory.getLogger(URLValidator.class);

    private final boolean allowInternal;

    /**
     * Constructs URL validator.
     *
     * @param allowInternal if true, internal/private network addresses are allowed (disables SSRF protection)
     */
    public URLValidator(boolean allowInternal)
    {
        this.allowInternal = allowInternal;
    }

    /**
     * Validates that the URI does not point to an internal/private network address.
     * Prevents SSRF attacks by blocking access to:
     * - Wildcard/any-local addresses (0.0.0.0, ::)
     * - RFC 1918 private addresses (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, fec0::/10)
     * - Link-local addresses (169.254.0.0/16, fe80::/10)
     *
     * All addresses the host resolves to are checked (not just the first), narrowing the DNS-rebinding
     * window where a host publishes both a public and an internal address.
     *
     * Loopback addresses (127.0.0.0/8, ::1) are intentionally NOT blocked: LinkedDataHub dereferences
     * its own documents and WebIDs on the same origin (which is loopback in local/test deployments), while
     * the backend triplestore is reached over a private/site-local address (blocked above), not loopback.
     * The {@code ALLOW_INTERNAL_URLS} escape hatch disables all checks for fully-internal deployments.
     *
     * @param uri the URI to validate
     * @return the validated URI
     * @throws IllegalArgumentException if the URI is null or its host is null
     * @throws InternalURLException if the URI resolves to an internal IP address
     */
    public URI validate(URI uri)
    {
        return validate(uri, false);
    }

    /**
     * Validates a URI another service of the deployment is to call on the platform's behalf, refusing loopback
     * addresses as well, and refusing internal addresses whether or not the deployment allows them elsewhere.
     * <p>
     * The triplestore executes a query's <code>SERVICE</code> clauses, and its JVM is itself what loopback names
     * there, so a loopback target would read a sibling dataset of the same server without the proxy that keeps it to
     * public addresses. The platform's own addresses that loopback stands for in local deployments - its dataspaces -
     * are matched and authorized before a target reaches this check ({@link ServiceRewriter}), so what is left on
     * loopback is internal. {@code ALLOW_INTERNAL_URLS} does not open this: it lets the platform dereference its own
     * documents and WebIDs on an internal address, and a query's targets that are the platform's own are matched as
     * dataspaces, never validated here, so an internal target here is a store or another service of the deployment,
     * which no deployment mode may read past the ACL.
     *
     * @param uri the URI to validate
     * @return the validated URI
     * @throws IllegalArgumentException if the URI is null or its host is null
     * @throws InternalURLException if the URI resolves to an internal or a loopback IP address
     */
    public URI validateRemote(URI uri)
    {
        return validate(uri, true, false);
    }

    private URI validate(URI uri, boolean refuseLoopback)
    {
        return validate(uri, refuseLoopback, allowInternal);
    }

    private URI validate(URI uri, boolean refuseLoopback, boolean allowInternal)
    {
        if (uri == null) throw new IllegalArgumentException("URI cannot be null");

        if (!allowInternal)
        {
            String host = uri.getHost();
            if (host == null) throw new IllegalArgumentException("URI host cannot be null");

            // Resolve hostname to all IPs and reject if any is wildcard/private/internal (loopback allowed unless asked)
            try
            {
                for (InetAddress address : InetAddress.getAllByName(host))
                {
                    if (address.isAnyLocalAddress())
                        throw new InternalURLException(uri, address.getHostAddress());
                    if (address.isLinkLocalAddress())
                        throw new InternalURLException(uri, address.getHostAddress());
                    if (address.isSiteLocalAddress())
                        throw new InternalURLException(uri, address.getHostAddress());
                    if (refuseLoopback && address.isLoopbackAddress())
                        throw new InternalURLException(uri, address.getHostAddress());
                }
            }
            catch (UnknownHostException e)
            {
                if (log.isWarnEnabled()) log.warn("Could not resolve hostname for SSRF validation: {}", host);
                // Allow request to proceed - will fail later with better error message
            }
        }

        return uri;
    }

}
