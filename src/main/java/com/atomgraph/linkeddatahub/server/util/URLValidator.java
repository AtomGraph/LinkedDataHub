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

    private final URI uri;

    /**
     * Constructs URL validator for the given URI.
     *
     * @param uri the URI to validate
     * @throws IllegalArgumentException if the URI is null
     */
    public URLValidator(URI uri)
    {
        if (uri == null) throw new IllegalArgumentException("URI cannot be null");
        this.uri = uri;
    }

    /**
     * Validates that the URI does not point to an internal/private network address.
     * Prevents SSRF attacks by blocking access to:
     * - RFC 1918 private addresses (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, fc00::/7)
     * - Link-local addresses (169.254.0.0/16, fe80::/10)
     *
     * Note: Loopback addresses (127.0.0.1, localhost, ::1) are NOT blocked as the application
     * may legitimately need to access resources on the same server (e.g., transformation queries,
     * WebID documents during development, admin operations).
     *
     * @return the validated URI
     * @throws IllegalArgumentException if the URI host is null
     * @throws InternalURLException if the URI resolves to an internal IP address
     */
    public URI validate()
    {
        String host = uri.getHost();
        if (host == null) throw new IllegalArgumentException("URI host cannot be null");

        // Resolve hostname to IP and check if it's private/internal
        try
        {
            InetAddress address = InetAddress.getByName(host);

            // Note: We don't block loopback addresses (127.0.0.1, localhost) because the application
            // legitimately accesses its own endpoints for various operations

            if (address.isLinkLocalAddress())
                throw new InternalURLException(uri, address.getHostAddress());
            if (address.isSiteLocalAddress())
                throw new InternalURLException(uri, address.getHostAddress());
        }
        catch (UnknownHostException e)
        {
            if (log.isWarnEnabled()) log.warn("Could not resolve hostname for SSRF validation: {}", host);
            // Allow request to proceed - will fail later with better error message
        }

        return uri;
    }

    /**
     * Returns the URI being validated.
     *
     * @return the URI
     */
    public URI getURI()
    {
        return uri;
    }

}
