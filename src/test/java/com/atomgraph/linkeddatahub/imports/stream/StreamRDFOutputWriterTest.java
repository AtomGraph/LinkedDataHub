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
package com.atomgraph.linkeddatahub.imports.stream;

import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link StreamRDFOutputWriter}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class StreamRDFOutputWriterTest
{

    @Mock private Service service;
    @Mock private Service adminService;
    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private GraphStoreClient gsc;

    private static final String BASE_URI = "http://localhost/";
    private static final String GRAPH_URI = "http://localhost/graphs/import";

    private Query query;
    private StreamRDFOutputWriter writer;

    @BeforeEach
    public void setUp()
    {
        query = QueryFactory.create("CONSTRUCT WHERE { ?s ?p ?o }");
        writer = new StreamRDFOutputWriter(service, adminService, system, gsc, BASE_URI, query, GRAPH_URI);
    }

    @Test
    public void testGettersRoundTrip()
    {
        assertSame(service, writer.getService());
        assertSame(adminService, writer.getAdminService());
        assertSame(system, writer.getSystem());
        assertSame(gsc, writer.getGraphStoreClient());
        assertEquals(BASE_URI, writer.getBaseURI());
        assertSame(query, writer.getQuery());
        assertEquals(GRAPH_URI, writer.getGraphURI());
    }

    @Test
    public void testApplyNullResponse()
    {
        assertThrows(IllegalArgumentException.class, () -> writer.apply(null));
    }

    /**
     * A response whose {@code Content-Type} does not map to an RDF language must be rejected with
     * {@code 400 Bad Request} — after the body has been buffered to a temp file but before any
     * Graph Store write is attempted.
     */
    @Test
    public void testApplyNonRdfMediaTypeThrowsBadRequest()
    {
        Response response = mock(Response.class);
        lenient().when(response.readEntity(InputStream.class)).thenReturn((InputStream)new ByteArrayInputStream("not rdf".getBytes()));
        when(response.getMediaType()).thenReturn(MediaType.valueOf("image/png"));

        assertThrows(BadRequestException.class, () -> writer.apply(response));
    }

}
