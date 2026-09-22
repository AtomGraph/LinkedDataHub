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

import com.atomgraph.client.util.jena.PrefixGraphRepository;
import java.io.IOException;
import java.io.InputStream;
import java.util.Optional;
import org.apache.commons.io.IOUtils;

/**
 * Reads the bytes of a URI that the graph repository maps to a bundled file.
 *
 * The repository owns the URI-to-location mapping but hands back RDF graphs, and not everything mapped
 * is RDF: a package's stylesheet is mapped so that the package resolves without leaving the JVM, and
 * asking the repository for its graph would try to parse XSLT as RDF. So the location is resolved and
 * the bytes are read straight off the classpath.
 *
 * Both readers of a bundled package stylesheet want exactly this, and having it twice is how the two
 * drift apart.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class MappedLocation
{

    private MappedLocation()
    {
    }

    /**
     * Returns the bytes of a mapped URI, or empty if the repository does not map it.
     * A URI that is mapped to a location which is not on the classpath is a broken build rather than a
     * cue to look elsewhere, so it fails instead of returning empty.
     *
     * @param repository graph repository owning the mapping, or null when there is none
     * @param uri URI to read
     * @return the bytes, or empty if the URI is not mapped
     * @throws IOException if the URI is mapped but its location cannot be read
     */
    public static Optional<byte[]> read(PrefixGraphRepository repository, String uri) throws IOException
    {
        // the repository is optional: an application can exist without one, and an unguarded call fails
        // every resolution that is not a bundled file
        if (repository == null || !repository.isMapped(uri)) return Optional.empty();

        String location = repository.resolve(uri);
        try (InputStream is = MappedLocation.class.getClassLoader().getResourceAsStream(location))
        {
            if (is == null) throw new IOException("URI <" + uri + "> is mapped to '" + location + "', which is not on the classpath");

            return Optional.of(IOUtils.toByteArray(is));
        }
    }

}
