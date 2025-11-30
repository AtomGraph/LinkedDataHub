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

import java.net.URI;

/**
 * Utility for converting URIs to filesystem paths.
 * Reverses hostname components following Java package naming conventions.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class UriPath
{

    /**
     * Converts a URI to a filesystem path by reversing hostname components.
     * Example: https://packages.linkeddatahub.com/skos/#this -> com/linkeddatahub/packages/skos
     *
     * @param uri the URI string
     * @return filesystem path relative to static directory
     * @throws IllegalArgumentException if URI is invalid
     */
    public static String convert(String uri)
    {
        if (uri == null)
            throw new IllegalArgumentException("URI cannot be null");

        try
        {
            URI uriObj = URI.create(uri);
            String host = uriObj.getHost();
            String path = uriObj.getPath();

            if (host == null)
                throw new IllegalArgumentException("URI must have a host: " + uri);

            // Reverse hostname components: packages.linkeddatahub.com -> com/linkeddatahub/packages
            String[] hostParts = host.split("\\.");
            StringBuilder reversedHost = new StringBuilder();
            for (int i = hostParts.length - 1; i >= 0; i--)
            {
                reversedHost.append(hostParts[i]);
                if (i > 0) reversedHost.append("/");
            }

            // Append path without leading/trailing slashes and fragment
            if (path != null && !path.isEmpty() && !path.equals("/"))
            {
                String cleanPath = path.replaceAll("^/+|/+$", ""); // Remove leading/trailing slashes
                return reversedHost + "/" + cleanPath;
            }

            return reversedHost.toString();
        }
        catch (IllegalArgumentException e)
        {
            throw new IllegalArgumentException("Invalid URI: " + uri, e);
        }
    }

}
