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

import java.net.URI;
import java.util.List;
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

/**
 * Tests reading link targets from the folded <code>Link</code> header the platform sends.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LinksTest
{

    private static final String ADMIN = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#admin";
    private static final String ONTOLOGY = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#ontology";
    /** The shape ResponseHeadersFilter folds its links into: one header, comma-separated */
    private static final String FOLDED = "<https://localhost:4443/sparql>; rel=\"http://www.w3.org/ns/sparql-service-description#endpoint\", " +
        "<urn:linkeddatahub:apps/end-user>; rel=\"https://w3id.org/atomgraph/linkeddatahub/dataspaces#dataspace\", " +
        "<https://localhost:4443/ns#>; rel=\"" + ONTOLOGY + "\", " +
        "<https://admin.localhost:4443/>; rel=\"" + ADMIN + "\"";

    @Test
    public void findsTargetByRelInFoldedHeader()
    {
        assertEquals(List.of(URI.create("https://admin.localhost:4443/")), Links.targets(FOLDED, ADMIN));
        assertEquals(List.of(URI.create("https://localhost:4443/ns#")), Links.targets(FOLDED, ONTOLOGY));
    }

    @Test
    public void absentRelYieldsNothing()
    {
        assertEquals(List.of(), Links.targets(FOLDED, "timemap"));
    }

    @Test
    public void relMustMatchWholeNotPrefix()
    {
        // lds:dataspace must not match a query for a rel that is its prefix
        assertEquals(List.of(), Links.targets(FOLDED, "https://w3id.org/atomgraph/linkeddatahub/dataspaces#data"));
    }

    @Test
    public void targetWithCommaIsNotSplit()
    {
        assertEquals(List.of(URI.create("https://localhost:4443/a,b/")), Links.targets("<https://localhost:4443/a,b/>; rel=\"timemap\"", "timemap"));
    }

    @Test
    public void unquotedAndMultipleRels()
    {
        assertEquals(List.of(URI.create("https://localhost:4443/tm")), Links.targets("<https://localhost:4443/tm>; rel=timemap", "timemap"));
        assertEquals(List.of(URI.create("https://localhost:4443/x")), Links.targets("<https://localhost:4443/x>; rel=\"self timemap\"", "timemap"));
    }

}
