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

/**
 * Sends a request somewhere other than where its URI says.
 * <p>
 * This is the <code>--proxy</code> option: a document's URI identifies it, but the host that
 * answers for it may be a different one - the client-certificate port, say, or a tunnel. The
 * logical URI stays in the request; only the origin it is sent to changes.
 * <p>
 * A CLI concern, not a document-shape one, which is why it stays here while the URI conventions
 * the platform itself applies live in {@link com.atomgraph.linkeddatahub.rdf.URIs}.
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
    private static String origin(URI uri)
    {
        if (uri.getScheme() == null || uri.getRawAuthority() == null) throw new IllegalArgumentException("URI '" + uri + "' is not absolute");

        return uri.getScheme() + "://" + uri.getRawAuthority();
    }

}
