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

package com.atomgraph.linkeddatahub.cli.util;

import java.net.URI;
import java.nio.charset.StandardCharsets;

/**
 * URI manipulation helpers matching the conventions of the <code>bin/</code> shell scripts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class URIRewriter
{

    private URIRewriter() { }

    /**
     * Replaces the origin (scheme and authority) of a URI with the origin of the proxy URI,
     * keeping the path, query and fragment.
     *
     * @param uri logical URI
     * @param proxy proxy URI whose origin is substituted
     * @return rewritten URI
     */
    public static URI rewrite(URI uri, URI proxy)
    {
        return URI.create(origin(proxy) + uri.toString().substring(origin(uri).length()));
    }

    /**
     * Returns the origin (scheme and authority) of a URI.
     *
     * @param uri URI
     * @return origin string, e.g. <code>https://localhost:4443</code>
     */
    public static String origin(URI uri)
    {
        if (uri.getScheme() == null || uri.getRawAuthority() == null) throw new IllegalArgumentException("URI '" + uri + "' is not absolute");

        return uri.getScheme() + "://" + uri.getRawAuthority();
    }

    /**
     * Converts an end-user application base URI to the base URI of its admin application
     * by prefixing the host with the <code>admin.</code> subdomain.
     *
     * @param base end-user base URI
     * @return admin base URI
     */
    public static URI adminBase(URI base)
    {
        return URI.create(base.toString().replaceFirst("://", "://admin."));
    }

    /**
     * Percent-encodes a string as a URI path segment. All characters except RFC 3986
     * unreserved ones are encoded, including <code>/</code>.
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
     * Builds the URI of a child document from the parent container URI and a path segment slug.
     *
     * @param parent parent container URI (with trailing slash)
     * @param slug path segment
     * @return child document URI (with trailing slash)
     */
    public static URI childURI(URI parent, String slug)
    {
        return URI.create(parent.toString() + encodeSlug(slug) + "/");
    }

}
