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

import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import jakarta.ws.rs.BadRequestException;
import java.net.URI;
import java.util.Map;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ServiceTargets}: which <code>SERVICE</code> targets a query may name. Hosts are IP literals or
 * names of the mocked dataspaces, so no name is resolved.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceTargetsTest
{

    private static final URI PEOPLE = URI.create("https://people.example/");

    private ServiceTargets targets;

    @BeforeEach
    public void setUp()
    {
        Dataspace people = mock(Dataspace.class);
        when(people.getBaseURI()).thenReturn(PEOPLE);
        Map<URI, Dataspace> byOrigin = Map.of(PEOPLE, people);
        targets = new ServiceTargets(uri -> byOrigin.get(uri.resolve("/")), new URLValidator(true));
    }

    @Test
    public void testADataspaceEndpointIsLeftToItsDoor()
    {
        Query query = QueryFactory.create("SELECT * { SERVICE <https://people.example/sparql> { ?s ?p ?o } }");

        assertSame(query, targets.check(query));
    }

    @Test
    public void testADataspaceNamedByAnythingButItsEndpointIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> targets.check(QueryFactory.create("SELECT * { SERVICE <https://people.example/documents/> { ?s ?p ?o } }")));
        assertThrows(BadRequestException.class,
            () -> targets.check(QueryFactory.create("SELECT * { SERVICE <https://people.example/> { ?s ?p ?o } }")));
    }

    @Test
    public void testAVariableTargetIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> targets.check(QueryFactory.create("SELECT * { ?s <http://example.org/endpoint> ?endpoint . SERVICE ?endpoint { ?s ?p ?o } }")));
    }

    @Test
    public void testAnInternalTargetIsRefusedEvenWhenInternalUrlsAreAllowed()
    {
        // the validator above allows internal URLs, as the test stacks do; a SERVICE target is refused regardless
        assertThrows(InternalURLException.class,
            () -> targets.check(QueryFactory.create("SELECT * { SERVICE SILENT <http://10.0.0.5:3030/admin/> { ?s ?p ?o } }")));
        assertThrows(InternalURLException.class,
            () -> targets.check(QueryFactory.create("SELECT * { SERVICE <http://127.0.0.1:3030/admin/> { ?s ?p ?o } }")));
    }

    @Test
    public void testAPublicTargetIsLeftAsItIs()
    {
        Query query = QueryFactory.create("SELECT * { SERVICE SILENT <http://93.184.216.34/sparql> { ?s ?p ?o } }");

        assertSame(query, targets.check(query));
    }

    @Test
    public void testAQueryWithoutServiceIsUnchanged()
    {
        Query query = QueryFactory.create("SELECT * { ?s ?p ?o } LIMIT 1");

        assertEquals(query, targets.check(query));
    }

    @Test
    public void testNestedServicesAreDecidedToo()
    {
        assertThrows(InternalURLException.class, () -> targets.check(QueryFactory.create("""
            SELECT * {
              { SELECT ?s { SERVICE <https://people.example/sparql> { ?s a <http://schema.org/Person> } } }
              FILTER NOT EXISTS { SERVICE <http://10.0.0.5:3030/admin/> { ?s <http://schema.org/email> ?e } }
            }""")));
    }

}
