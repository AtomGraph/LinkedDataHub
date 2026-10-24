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
import jakarta.ws.rs.WebApplicationException;
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
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * The write semantics of {@link DocumentHierarchyGraphStoreImpl} against an in-memory store.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentHierarchyGraphStoreImplWriteTest
{

    private static final URI BASE = URI.create("https://localhost:4443/");
    private static final URI DOC = URI.create("https://localhost:4443/doc/");

    private final AtomicReference<Model> graph = new AtomicReference<>();
    private GraphStoreClient store;
    private Request request;
    private HttpHeaders headers;
    private Application system;
    private Service service;
    private Dataspace dataspace;

    @BeforeEach
    public void setUp()
    {
        Model initial = ModelFactory.createDefaultModel();
        initial.createResource(DOC.toString()).addProperty(DCTerms.title, "Doc");
        graph.set(initial);

        store = mock(GraphStoreClient.class);
        doAnswer(inv -> ModelFactory.createDefaultModel().add(graph.get())).when(store).getModel(anyString());
        doAnswer(inv ->
        {
            graph.set(inv.getArgument(1));
            return null;
        }).when(store).putModel(anyString(), any(Model.class));

        ServiceContext serviceContext = mock(ServiceContext.class);
        when(serviceContext.getGraphStoreClient()).thenReturn(store);
        service = mock(Service.class);

        system = mock(Application.class);
        when(system.getServiceContext(service)).thenReturn(serviceContext);
        when(system.getGraphLocks()).thenReturn(new GraphLocks());
        when(system.getSecretaryWebIDURI()).thenReturn(URI.create("https://localhost:4443/acl/agents/secretary/#this"));

        dataspace = mock(Dataspace.class);
        when(dataspace.getMaker()).thenReturn(org.apache.jena.rdf.model.ResourceFactory.createResource("https://localhost:4443/acl/agents/owner/#this"));
        when(dataspace.getBaseURI()).thenReturn(BASE);

        // the request accepts the first variant offered unless a test says otherwise
        request = mock(Request.class);
        when(request.selectVariant(anyList())).thenAnswer(inv -> ((List<Variant>)inv.getArgument(0)).get(0));

        headers = mock(HttpHeaders.class);
        when(headers.getAcceptableLanguages()).thenReturn(List.of());
    }

    private DocumentHierarchyGraphStoreImpl graphStore(URI uri)
    {
        UriInfo uriInfo = mock(UriInfo.class);
        when(uriInfo.getAbsolutePath()).thenReturn(uri);
        when(uriInfo.getBaseUri()).thenReturn(BASE);
        when(uriInfo.getBaseUriBuilder()).thenAnswer(inv -> UriBuilder.fromUri(BASE));
        when(uriInfo.getQueryParameters()).thenReturn(new MultivaluedHashMap<>());

        DocumentHierarchyGraphStoreImpl gs = spy(new DocumentHierarchyGraphStoreImpl(request, uriInfo, new MediaTypes(), dataspace,
            Optional.of(OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM)), Optional.of(service),
            mock(SecurityContext.class), Optional.empty(), mock(Providers.class), system, headers));
        doReturn(List.of(com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE, com.atomgraph.core.MediaType.TEXT_TURTLE_TYPE)).when(gs).getWritableMediaTypes(any());
        doReturn(List.of()).when(gs).getLanguages();
        doNothing().when(gs).validateConstraints(any(Model.class));
        return gs;
    }

    // item 8: an empty POST is a no-op

    @Test
    public void emptyPostIsANoOpWithoutPrecondition()
    {
        DocumentHierarchyGraphStoreImpl gs = graphStore(DOC);
        Model before = graph.get();

        Response response = gs.post(ModelFactory.createDefaultModel());

        assertEquals(Response.Status.NO_CONTENT.getStatusCode(), response.getStatus(), "no If-Match is needed to append nothing");
        verify(store, never()).getModel(anyString());
        verify(store, never()).putModel(anyString(), any(Model.class));
        assertEquals(before, graph.get(), "the graph is untouched");
    }

    // item 13: a PATCH that empties a document that cannot be deleted

    @Test
    public void patchEmptyingTheRootIsUnprocessable()
    {
        DocumentHierarchyGraphStoreImpl gs = graphStore(BASE);
        String current = gs.getInternalResponse(graph.get(), BASE).getVariantEntityTag().getValue(); // the current tag, so the update is what fails
        when(request.getMethod()).thenReturn("PATCH");
        when(headers.getHeaderString(HttpHeaders.IF_MATCH)).thenReturn("\"" + current + "\"");

        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> gs.patch(UpdateFactory.create("DELETE WHERE { ?s ?p ?o }")));

        assertEquals(422, ex.getResponse().getStatus(), "PATCH is supported on the root; the update is what cannot be applied");
        verify(store, never()).putModel(anyString(), any(Model.class));
    }

    // item 14: the 428 says what to send

    @Test
    public void preconditionRequiredExplainsItself()
    {
        DocumentHierarchyGraphStoreImpl gs = graphStore(DOC);
        Model payload = ModelFactory.createDefaultModel();
        payload.createResource(DOC.toString()).addProperty(DCTerms.description, "appended");

        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> gs.post(payload));

        assertEquals(428, ex.getResponse().getStatus());
        assertEquals("text/plain", ex.getResponse().getMediaType().getType() + "/" + ex.getResponse().getMediaType().getSubtype());
        String body = (String)ex.getResponse().getEntity();
        assertTrue(body.contains("If-Match"), "names the precondition");
        assertTrue(body.contains("HEAD"), "says where to get the entity tag");
        verify(store, never()).putModel(anyString(), any(Model.class));
    }

    // item 15: a write whose Accept names no RDF syntax is not refused with 406

    private DocumentHierarchyGraphStoreImpl unnegotiable(String ifMatch)
    {
        DocumentHierarchyGraphStoreImpl gs = graphStore(DOC);
        // the tag a client read with Accept: application/n-triples, before the request that accepts none of them
        EntityTag ntriples = gs.getInternalResponse(graph.get(), DOC).getVariantEntityTag();

        doReturn(null).when(request).selectVariant(anyList()); // e.g. Accept: application/sparql-results+json
        String quoted = ifMatch != null ? ifMatch : ntriples.getValue();
        when(request.getMethod()).thenReturn("POST");
        when(headers.getHeaderString(HttpHeaders.IF_MATCH)).thenReturn("\"" + quoted + "\"");
        return gs;
    }

    @Test
    public void unnegotiableWriteQuotingAnyVariantsTagIsAccepted()
    {
        DocumentHierarchyGraphStoreImpl gs = unnegotiable(null);

        assertEquals(null, gs.evaluatePreconditions(graph.get(), headers), "the tag of the N-Triples variant identifies the current state");

        Model payload = ModelFactory.createDefaultModel();
        payload.createResource(DOC.toString()).addProperty(DCTerms.description, "appended");
        Response response = gs.post(payload);
        assertEquals(Response.Status.NO_CONTENT.getStatusCode(), response.getStatus());
        assertEquals(null, response.getEntityTag(), "no variant was negotiated, so no variant's tag is sent");
        assertTrue(graph.get().contains(graph.get().createResource(DOC.toString()), DCTerms.description, "appended"));
    }

    @Test
    public void unnegotiableDeleteIsNoContent()
    {
        DocumentHierarchyGraphStoreImpl gs = unnegotiable(null);
        when(store.containsModel(DOC.toString())).thenReturn(true);
        doReturn(false).when(gs).hasChild(DOC);
        when(request.getMethod()).thenReturn("DELETE");

        assertEquals(Response.Status.NO_CONTENT.getStatusCode(), gs.delete().getStatus());
        verify(store).deleteModel(DOC.toString());
    }

    @Test
    public void deleteOfDocumentWithChildIsConflict() // like rmdir: the children go first
    {
        DocumentHierarchyGraphStoreImpl gs = unnegotiable(null);
        when(store.containsModel(DOC.toString())).thenReturn(true);
        doReturn(true).when(gs).hasChild(DOC);

        WebApplicationException ex = assertThrows(WebApplicationException.class, gs::delete);
        assertEquals(Response.Status.CONFLICT.getStatusCode(), ex.getResponse().getStatus());
        verify(store, never()).deleteModel(anyString());
    }

    @Test
    public void unnegotiableWriteQuotingAStaleTagFails()
    {
        DocumentHierarchyGraphStoreImpl gs = unnegotiable("0000000000000000");

        Response.ResponseBuilder rb = gs.evaluatePreconditions(graph.get(), headers);
        assertEquals(Response.Status.PRECONDITION_FAILED.getStatusCode(), rb.build().getStatus());
    }

}
