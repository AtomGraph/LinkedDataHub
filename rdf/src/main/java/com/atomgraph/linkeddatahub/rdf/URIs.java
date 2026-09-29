/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.rdf;

import java.net.URI;
import java.nio.charset.StandardCharsets;

/**
 * Where LinkedDataHub puts things: how a child document's URI is derived from its parent and a
 * slug, and how an end-user application's base URI relates to its admin application's.
 * <p>
 * Conventions, not manipulation - every method here encodes a rule the platform also applies, so
 * a client that follows them addresses documents the platform will agree exist.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class URIs
{

    private URIs() { }

    /**
     * Builds the URI of a child document from the parent container URI and a path segment slug.
     * <p>
     * The trailing slash is what makes it a container-addressable document rather than a fragment
     * of its parent, so it is added here rather than left to the caller.
     *
     * @param parent parent container URI (with trailing slash)
     * @param slug path segment
     * @return child document URI (with trailing slash)
     */
    public static URI childURI(URI parent, String slug)
    {
        return URI.create(parent.toString() + encodeSlug(slug) + "/");
    }

    /**
     * Percent-encodes a string as a URI path segment. All characters except RFC 3986
     * unreserved ones are encoded, including <code>/</code> - a slug names one segment, so a
     * slash in it is data rather than a further step in the path.
     *
     * @param slug path segment
     * @return encoded path segment
     */
    public static String encodeSlug(String slug)
    {
        StringBuilder sb = new StringBuilder();

        for (byte b : slug.getBytes(StandardCharsets.UTF_8))
        {
            char c = (char)(b & 0xFF);
            if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
                    c == '-' || c == '.' || c == '_' || c == '~') sb.append(c);
            else sb.append('%').append(String.format("%02X", b & 0xFF));
        }

        return sb.toString();
    }

    /**
     * Converts an end-user application base URI to the base URI of its admin application
     * by prefixing the host with the <code>admin.</code> subdomain, which is how nginx's
     * wildcard routing tells the two apart.
     *
     * @param base end-user base URI
     * @return admin base URI
     */
    public static URI adminBase(URI base)
    {
        return URI.create(base.toString().replaceFirst("://", "://admin."));
    }

}
