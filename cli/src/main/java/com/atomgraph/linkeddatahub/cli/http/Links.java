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

package com.atomgraph.linkeddatahub.cli.http;

import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Reads <code>Link</code> response headers (RFC 8288).
 * <p>
 * The platform folds all its links into one comma-separated header, so entries are told apart by their
 * <code>&lt;target&gt;</code>, not by splitting on commas, which a target URI may contain.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Links
{

    private static final Pattern ENTRY = Pattern.compile("<([^>]+)>([^<]*)");
    private static final Pattern REL = Pattern.compile("(?:^|;)\\s*rel\\s*=\\s*(?:\"([^\"]*)\"|([^\\s;,]+))");

    private Links() { }

    /**
     * Returns the targets of the response's links with the given relation.
     *
     * @param response HTTP response
     * @param rel relation URI or name
     * @return link targets, in header order
     */
    public static List<URI> targets(Response response, String rel)
    {
        List<URI> targets = new ArrayList<>();

        for (String header : response.getStringHeaders().getOrDefault(HttpHeaders.LINK, List.of()))
            targets.addAll(targets(header, rel));

        return targets;
    }

    /**
     * Returns the targets of the links in a header value with the given relation.
     *
     * @param header <code>Link</code> header value, possibly with several comma-separated links
     * @param rel relation URI or name
     * @return link targets, in header order
     */
    public static List<URI> targets(String header, String rel)
    {
        List<URI> targets = new ArrayList<>();
        Matcher entry = ENTRY.matcher(header);

        while (entry.find())
        {
            Matcher params = REL.matcher(entry.group(2));
            if (!params.find()) continue;

            String rels = params.group(1) != null ? params.group(1) : params.group(2);
            if (Arrays.asList(rels.trim().split("\\s+")).contains(rel)) targets.add(URI.create(entry.group(1)));
        }

        return targets;
    }

}
