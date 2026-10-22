/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.server.util.GraphLocks;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.container.ResourceContext;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Variant;
import jakarta.ws.rs.ext.Providers;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * A settings <code>PATCH</code> is held to the terms of a write to an existing document: it quotes the state it was
 * made against, and concurrent ones quoting the same state are accepted once.
 * <p>
 * The settings are read, changed in memory and written back over separate calls, so the <code>If-Match</code> check
 * alone cannot refuse a second writer that read them before the first one wrote. The store here takes long enough to
 * write for every writer to have read the settings before any has written, which is the interleaving that loses an
 * update - two <code>ldh packages add</code> at once, one <code>ldh:import</code> gone.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SettingsTest
{

    private static final String APP = "https://localhost:4443/";
    private static final int WRITERS = 8;
    private static final long WRITE_DELAY_MS = 200;

    private final AtomicReference<Model> settings = new AtomicReference<>();
    private final AtomicReference<String> ifMatch = new AtomicReference<>();
    private Application system;
    private Settings resource;
    private EntityTag quoted; // the tag every writer read before any of them wrote

    @BeforeEach
    public void setUp()
    {
        Model initial = ModelFactory.createDefaultModel();
        initial.createResource(APP).
            addProperty(RDF.type, LDS.EndUserDataspace).
            addProperty(DCTerms.title, "Settings");
        settings.set(initial);

        Dataspace dataspace = mock(Dataspace.class);
        when(dataspace.getURI()).thenReturn(APP);

        // a read answers a copy of the settings as they stand; a write replaces them, slowly
        system = mock(Application.class);
        when(system.getGraphLocks()).thenReturn(new GraphLocks());
        when(system.getSupportedLanguages()).thenReturn(List.of());
        when(system.getDataspaceModel(dataspace)).thenAnswer(inv -> ModelFactory.createDefaultModel().add(settings.get()));
        try
        {
            doAnswer(inv ->
            {
                Thread.sleep(WRITE_DELAY_MS);
                settings.set(inv.getArgument(1));
                return null;
            }).when(system).updateApp(eq(dataspace), any(Model.class));
        }
        catch (Exception ex)
        {
            throw new IllegalStateException(ex);
        }

        Request request = mock(Request.class);
        when(request.getMethod()).thenReturn("PATCH");
        when(request.selectVariant(anyList())).thenAnswer(inv -> ((List<Variant>)inv.getArgument(0)).get(0));

        // the precondition is evaluated from the headers: it holds when the tag the settings answer now is the one quoted
        HttpHeaders headers = mock(HttpHeaders.class);
        when(headers.getHeaderString(HttpHeaders.IF_MATCH)).thenAnswer(inv -> ifMatch.get());

        resource = spy(new Settings(dataspace, system, new MediaTypes(), mock(Providers.class), request, mock(ResourceContext.class), headers));
        doAnswer(inv -> inv.getArgument(0)).when(resource).validate(any(Model.class));

        quoted = resource.getInternalResponse(initial).getVariantEntityTag();
    }

    private UpdateRequest retitle(String title)
    {
        return UpdateFactory.create("PREFIX dct: <http://purl.org/dc/terms/> " +
            "DELETE { ?app dct:title ?title } INSERT { ?app dct:title \"" + title + "\" } WHERE { ?app dct:title ?title }");
    }

    @Test
    public void patchWithoutIfMatchIsRefused428() throws Exception
    {
        ifMatch.set(null);

        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> resource.patch(retitle("Unconditional")));
        assertEquals(Response.Status.PRECONDITION_REQUIRED.getStatusCode(), ex.getResponse().getStatus());
        verify(system, never()).updateApp(any(), any());
        assertTrue(system.getGraphLocks().get(URI.create(APP)).tryLock(), "the refusal released the lock");
    }

    @Test
    public void patchWithWildcardIfMatchIsRefused428() throws Exception
    {
        ifMatch.set("*");

        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> resource.patch(retitle("Wildcard")));
        assertEquals(Response.Status.PRECONDITION_REQUIRED.getStatusCode(), ex.getResponse().getStatus());
        verify(system, never()).updateApp(any(), any());
    }

    @Test
    public void patchWithStaleTagIsRefused412NamingTheCurrentOne() throws Exception
    {
        ifMatch.set("\"stale\"");

        try (Response response = resource.patch(retitle("Stale")))
        {
            assertEquals(Response.Status.PRECONDITION_FAILED.getStatusCode(), response.getStatus());
            assertEquals(quoted, response.getEntityTag());
        }
        verify(system, never()).updateApp(any(), any());
    }

    @Test
    public void acceptedPatchAnswersTheTagOfWhatItWrote() throws Exception
    {
        ifMatch.set(quoted.toString());

        try (Response response = resource.patch(retitle("Accepted")))
        {
            assertEquals(Response.Status.NO_CONTENT.getStatusCode(), response.getStatus());
            assertEquals(resource.getInternalResponse(settings.get()).getVariantEntityTag(), response.getEntityTag());
        }
    }

    @Test
    public void concurrentPatchesQuotingTheSameTagAreAcceptedOnce() throws Exception
    {
        ifMatch.set(quoted.toString());

        ExecutorService pool = Executors.newFixedThreadPool(WRITERS);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<Integer>> statuses = new ArrayList<>();
        for (int writer = 1; writer <= WRITERS; writer++)
        {
            UpdateRequest update = retitle("Writer " + writer);
            Callable<Integer> write = () ->
            {
                start.await();
                try (Response response = resource.patch(update))
                {
                    return response.getStatus();
                }
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

        assertEquals(1, accepted, "exactly one writer's tag matched the settings it was written against");
        assertEquals(WRITERS - 1, refused, "every other writer read the settings before the first wrote them and was refused");
        verify(system, times(1)).updateApp(any(), any(Model.class)); // the losers never reached the store
    }

}
