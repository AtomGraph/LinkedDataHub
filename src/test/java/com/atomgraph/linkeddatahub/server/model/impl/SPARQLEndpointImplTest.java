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
package com.atomgraph.linkeddatahub.server.model.impl;

import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Set;
import org.apache.jena.update.UpdateFactory;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.CALLS_REAL_METHODS;
import static org.mockito.Mockito.mock;

/**
 * Unit tests for the SPARQL Update refusal of {@link SPARQLEndpointImpl}.
 * The refusing entry points read no instance state, so the instance is a Mockito mock calling the real methods,
 * which skips the constructor and its service wiring.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPARQLEndpointImplTest
{

    private final SPARQLEndpointImpl endpoint = mock(SPARQLEndpointImpl.class, CALLS_REAL_METHODS);

    private static void assertNotAllowed(NotAllowedException ex)
    {
        Response response = ex.getResponse();
        assertEquals(Response.Status.METHOD_NOT_ALLOWED.getStatusCode(), response.getStatus());
        assertEquals(Set.of(HttpMethod.GET, HttpMethod.POST), response.getAllowedMethods());
    }

    @Test
    public void testSPARQLUpdateBodyNotAllowed()
    {
        NotAllowedException ex = assertThrows(NotAllowedException.class,
            () -> endpoint.post(UpdateFactory.create("DROP ALL"), List.of(), List.of()));
        assertNotAllowed(ex);
    }

    @Test
    public void testFormUpdateNotAllowed()
    {
        NotAllowedException ex = assertThrows(NotAllowedException.class,
            () -> endpoint.post(null, "DROP ALL", List.of(), List.of(), List.of(), List.of()));
        assertNotAllowed(ex);
    }

    @Test
    public void testFormUpdateNotAllowedAlongsideQuery()
    {
        NotAllowedException ex = assertThrows(NotAllowedException.class,
            () -> endpoint.post("ASK {}", "DROP ALL", List.of(), List.of(), List.of(), List.of()));
        assertNotAllowed(ex);
    }

}
