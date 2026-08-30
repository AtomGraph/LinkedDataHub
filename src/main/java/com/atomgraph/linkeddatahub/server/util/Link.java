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
package com.atomgraph.linkeddatahub.server.util;

import java.net.URI;

/**
 * <code>Link</code> header value that quotes its <code>type</code> parameter.
 * RFC 8288 allows a parameter value to be either a token or a quoted-string. A media type such as
 * <code>application/link-format</code> contains a solidus, which is not a <code>tchar</code>, so it
 * can only be conveyed as a quoted-string.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc8288#section-3">RFC 8288: Web Linking</a>
 */
public class Link extends com.atomgraph.core.util.Link
{

    /**
     * Constructs a link from a target URI, relation type and media type.
     *
     * @param href target URI
     * @param rel relation type
     * @param type media type of the target, or null
     */
    public Link(URI href, String rel, String type)
    {
        super(href, rel, type);
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder("<");
        builder.append(getHref()).append(">; rel=").append(getRel());
        if (getType() != null) builder.append("; type=\"").append(getType()).append("\"");
        return builder.toString();
    }

}
