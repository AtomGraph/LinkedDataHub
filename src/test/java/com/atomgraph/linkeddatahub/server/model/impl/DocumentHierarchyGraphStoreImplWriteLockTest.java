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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import com.atomgraph.linkeddatahub.server.util.GraphLocks;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.core.Variant;
import jakarta.ws.rs.ext.Providers;
import java.net.URI;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.ResourceFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Concurrent writes quoting the same entity tag: exactly one is accepted.
 * <p>
 * A write is a read-modify-write over separate calls to the store, so the <code>If-Match</code> check alone
 * cannot refuse a second writer that read the graph before the first one wrote it. The store here is an
 * in-memory stand-in that takes long enough to write for every writer to have read the graph before any has
 * written, which is the interleaving that loses an update. The graph's lock is what turns it into one
 * <code>204</code> and the rest <code>412</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentHierarchyGraphStoreImplWriteLockTest
{

    private static final URI BASE = URI.create("https://localhost:4443/");
    private static final URI DOC = URI.create("https://localhost:4443/concurrent/");
    private static final Property WROTE = ResourceFactory.createProperty("http://example.com/wrote");
    private static final int WRITERS = 8;
    private static final long WRITE_DELAY_MS = 200;

    private final AtomicReference<Model> graph = new AtomicReference<>();
    private GraphStoreClient store;
    private DocumentHierarchyGraphStoreImpl gs;
    private EntityTag quoted; // the tag every writer read before any of them wrote

    @BeforeEach
    public void setUp() throws NoSuchAlgorithmException
    {
        Model initial = ModelFactory.createDefaultModel();
        initial.createResource(DOC.toString()).addProperty(WROTE, "nobody yet");
        graph.set(initial);

        // a GET answers a copy of the graph as it stands; a PUT replaces it, slowly
        store = mock(GraphStoreClient.class);
        doAnswer(inv -> ModelFactory.createDefaultModel().add(graph.get())).when(store).getModel(DOC.toString());
        doAnswer(inv ->
        {
            Thread.sleep(WRITE_DELAY_MS);
            graph.set(inv.getArgument(1));
            return null;
        }).when(store).putModel(eq(DOC.toString()), any(Model.class));

        ServiceContext serviceContext = mock(ServiceContext.class);
        when(serviceContext.getGraphStoreClient()).thenReturn(store);
        Service service = mock(Service.class);

        Application system = mock(Application.class);
        when(system.getServiceContext(service)).thenReturn(serviceContext);
        when(system.getGraphLocks()).thenReturn(new GraphLocks());
        when(system.getSecretaryWebIDURI()).thenReturn(URI.create("https://localhost:4443/acl/agents/secretary/#this"));
        when(system.getMessageDigest()).thenReturn(MessageDigest.getInstance("SHA-1"));

        Dataspace dataspace = mock(Dataspace.class);
        when(dataspace.getMaker()).thenReturn(ResourceFactory.createResource("https://localhost:4443/acl/agents/owner/#this"));
        when(dataspace.getBaseURI()).thenReturn(BASE);

        UriInfo uriInfo = mock(UriInfo.class);
        when(uriInfo.getAbsolutePath()).thenReturn(DOC);
        when(uriInfo.getBaseUri()).thenReturn(BASE);
        when(uriInfo.getBaseUriBuilder()).thenAnswer(inv -> UriBuilder.fromUri(BASE));
        when(uriInfo.getQueryParameters()).thenReturn(new MultivaluedHashMap<>());

        // the precondition is the request's to evaluate: it holds when the tag the store answers now is the one quoted
        Request request = mock(Request.class);
        when(request.selectVariant(anyList())).thenAnswer(inv -> ((List<Variant>)inv.getArgument(0)).get(0));
        when(request.evaluatePreconditions(any(EntityTag.class))).thenAnswer(inv -> precondition(inv.getArgument(0)));
        when(request.evaluatePreconditions(any(Date.class), any(EntityTag.class))).thenAnswer(inv -> precondition(inv.getArgument(1)));

        HttpHeaders headers = mock(HttpHeaders.class);
        when(headers.getHeaderString(HttpHeaders.IF_MATCH)).thenAnswer(inv -> quoted.toString());
        when(headers.getAcceptableLanguages()).thenReturn(List.of());

        gs = spy(new DocumentHierarchyGraphStoreImpl(request, uriInfo, new MediaTypes(), dataspace,
            Optional.of(OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM)), Optional.of(service),
            mock(SecurityContext.class), Optional.empty(), mock(Providers.class), system, headers));
        doReturn(List.of(com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE)).when(gs).getWritableMediaTypes(any());
        doReturn(List.of()).when(gs).getLanguages();
        doNothing().when(gs).validateConstraints(any(Model.class));
        doNothing().when(gs).submitImports(any(Model.class));

        quoted = gs.getInternalResponse(initial, DOC).getVariantEntityTag();
    }

    private Response.ResponseBuilder precondition(EntityTag current)
    {
        return current.equals(quoted) ? null : Response.status(Response.Status.PRECONDITION_FAILED);
    }

    private Model payload(int writer)
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource(DOC.toString() + "#writer-" + writer).addProperty(WROTE, Integer.toString(writer));
        return model;
    }

    @Test
    public void concurrentWritersQuotingTheSameTagAreAcceptedOnce() throws Exception
    {
        ExecutorService pool = Executors.newFixedThreadPool(WRITERS);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<Integer>> statuses = new ArrayList<>();
        for (int writer = 1; writer <= WRITERS; writer++)
        {
            Model payload = payload(writer);
            Callable<Integer> write = () ->
            {
                start.await();
                return gs.post(payload).getStatus();
            };
            statuses.add(pool.submit(write));
        }
        start.countDown();
        pool.shutdown();
        assertTrue(pool.awaitTermination(30, TimeUnit.SECONDS));

        int accepted = 0, refused = 0;
        for (Future<Integer> status : statuses)
        {
            if (status.get() == Response.Status.NO_CONTENT.getStatusCode()) accepted++;
            if (status.get() == Response.Status.PRECONDITION_FAILED.getStatusCode()) refused++;
        }

        assertEquals(1, accepted, "exactly one writer's tag matched the graph it was written against");
        assertEquals(WRITERS - 1, refused, "every other writer read the graph before the first wrote it and was refused");
        verify(store, times(1)).putModel(eq(DOC.toString()), any(Model.class)); // the losers never reached the store
        assertEquals(1, graph.get().listStatements(null, WROTE, (String)null).filterDrop(stmt -> stmt.getSubject().getURI().equals(DOC.toString())).toList().size(),
            "the document holds the accepted write and no other");
    }

}
