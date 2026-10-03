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
import java.util.List;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;

/**
 * Tests for the link that keeps its target as given.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class LinkTest
{

    private static final String ONTOLOGY = "https://localhost:4443/ns#";
    private static final String ONTOLOGY_REL = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#ontology";

    @Test
    public void testAnEmptyFragmentSurvivesBuilding()
    {
        // Jersey's own builder writes <https://localhost:4443/ns>, a different URI
        assertEquals("<" + ONTOLOGY + ">; rel=\"" + ONTOLOGY_REL + "\"", Link.fromUri(URI.create(ONTOLOGY)).rel(ONTOLOGY_REL).build().toString());
    }

    @Test
    public void testAnEmptyFragmentSurvivesParsing()
    {
        Link link = Link.valueOf("<" + ONTOLOGY + ">; rel=\"" + ONTOLOGY_REL + "\"");

        assertEquals(URI.create(ONTOLOGY), link.getUri());
        assertEquals(ONTOLOGY_REL, link.getRel());
    }

    @Test
    public void testARoundTripIsLossless()
    {
        Link link = Link.fromUri(ONTOLOGY).rel(ONTOLOGY_REL).type("text/turtle").build();

        assertEquals(link, Link.valueOf(link.toString()));
    }

    @Test
    public void testAURIRelationTypeIsQuoted()
    {
        // ':', '/' and '#' are not token characters, so RFC 8288 requires the quotes
        assertEquals("<http://www.w3.org/ns/auth/acl#Read>; rel=\"http://www.w3.org/ns/auth/acl#mode\"",
            Link.fromUri("http://www.w3.org/ns/auth/acl#Read").rel("http://www.w3.org/ns/auth/acl#mode").build().toString());
    }

    @Test
    public void testAnUnquotedRelationTypeIsParsed()
    {
        // what the platform wrote before, and what an older peer behind the proxy may still write
        assertEquals("http://www.w3.org/ns/auth/acl#mode", Link.valueOf("<http://www.w3.org/ns/auth/acl#Read>; rel=http://www.w3.org/ns/auth/acl#mode").getRel());
    }

    @Test
    public void testRepeatedRelationTypesAreSpaceSeparated()
    {
        Link link = Link.fromUri("https://localhost:4443/doc/?version=abc").rel("first").rel("last").rel("memento").build();

        assertEquals("first last memento", link.getRel());
        assertEquals(List.of("first", "last", "memento"), link.getRels());
    }

    @Test
    public void testParametersKeepTheirOrder()
    {
        Link link = Link.fromUri("https://localhost:4443/doc/?timemap").rel("self").type("application/link-format").
            param("from", "Mon, 17 Aug 2026 10:00:00 GMT").param("until", "Mon, 17 Aug 2026 12:00:00 GMT").build();

        assertEquals(List.of("rel", "type", "from", "until"), List.copyOf(link.getParams().keySet()));
    }

    @Test
    public void testATargetIsResolvedAgainstTheBase()
    {
        assertEquals(URI.create("https://localhost:4443/sparql"), Link.fromUri("sparql").baseUri("https://localhost:4443/").rel("r").build().getUri());
    }

    @Test
    public void testAValueWithoutATargetIsRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> Link.valueOf("rel=\"self\""));
    }

}
