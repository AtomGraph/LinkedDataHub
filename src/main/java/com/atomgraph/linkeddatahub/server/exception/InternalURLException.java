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
package com.atomgraph.linkeddatahub.server.exception;

import java.net.URI;

/**
 * Exception thrown when attempting to load data from an internal/private network address.
 * This is part of SSRF (Server-Side Request Forgery) attack prevention.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/252">LNK-004: SSRF primitive via On-Behalf-Of header</a>
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/253">LNK-002: SSRF primitives in admin endpoint</a>
 * @see <a href="https://github.com/AtomGraph/LinkedDataHub/issues/287">LNK-009: SSRF via proxy URI parameter</a>
 */
public class InternalURLException extends RuntimeException
{

    /** The URI that resolves to an internal address */
    private final URI uri;

    /** The resolved IP address */
    private final String ipAddress;

    /**
     * Constructs exception for link-local address.
     *
     * @param uri the URI that resolves to a link-local address
     * @param ipAddress the resolved link-local IP address
     */
    public InternalURLException(URI uri, String ipAddress)
    {
        super("URL cannot resolve to internal addresses: " + ipAddress);
        this.uri = uri;
        this.ipAddress = ipAddress;
    }

    /**
     * Returns the URI that resolves to an internal address.
     *
     * @return the URI
     */
    public URI getURI()
    {
        return uri;
    }

    /**
     * Returns the resolved IP address.
     *
     * @return the IP address
     */
    public String getIPAddress()
    {
        return ipAddress;
    }

}
