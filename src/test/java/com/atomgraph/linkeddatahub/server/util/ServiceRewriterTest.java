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
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.server.security.DataspaceAuthorization;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import jakarta.ws.rs.BadRequestException;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementService;
import org.apache.jena.sparql.syntax.ElementVisitorBase;
import org.apache.jena.sparql.syntax.ElementWalker;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ServiceRewriter}: what becomes of each kind of <code>SERVICE</code> target.
 * The dataspaces are two of one deployment, <code>people</code> (read by its ACL) and <code>open</code> (public
 * read), reached at their stores; the agent is asked about through a mocked {@link DataspaceAuthorization}. Hosts
 * are IP literals, so no name is resolved.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceRewriterTest
{

    private static final URI PEOPLE = URI.create("https://people.example/"), OPEN = URI.create("https://open.example/");
    private static final String PEOPLE_STORE = "http://fuseki:3030/people.end-user/", OPEN_STORE = "http://fuseki:3030/open.end-user/";

    private Dataspace people, open;
    private DataspaceAuthorization authorization;
    private Agent agent;
    private ServiceRewriter rewriter;

    @BeforeEach
    public void setUp()
    {
        people = dataspace(PEOPLE, PEOPLE_STORE, false);
        open = dataspace(OPEN, OPEN_STORE, true);
        authorization = mock(DataspaceAuthorization.class);
        agent = mock(Agent.class);
        Map<URI, Dataspace> byOrigin = Map.of(PEOPLE, people, OPEN, open);
        rewriter = new ServiceRewriter(uri -> byOrigin.get(uri.resolve("/")), authorization, new URLValidator(false), agent);
    }

    private static Dataspace dataspace(URI base, String store, boolean readAllowed)
    {
        Service service = mock(Service.class);
        when(service.getSPARQLEndpoint()).thenReturn(ResourceFactory.createResource(store));
        Dataspace dataspace = mock(Dataspace.class);
        when(dataspace.getBaseURI()).thenReturn(base);
        when(dataspace.getService()).thenReturn(service);
        when(dataspace.isReadAllowed()).thenReturn(readAllowed);
        return dataspace;
    }

    private static Resource endpoint(URI base)
    {
        return ResourceFactory.createResource(base.resolve("sparql").toString());
    }

    private static List<ElementService> services(Query query)
    {
        List<ElementService> services = new ArrayList<>();
        ElementWalker.walk(query.getQueryPattern(), new ElementVisitorBase()
        {

            @Override
            public void visit(ElementService el)
            {
                services.add(el);
            }

        });
        return services;
    }

    @Test
    public void testAuthorizedDataspaceIsReachedAtItsStore()
    {
        when(authorization.authorize(eq(people), eq(endpoint(PEOPLE)), eq(agent), eq(ACL.Read))).thenReturn(ModelFactory.createDefaultModel());

        Query rewritten = rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/sparql> { ?s ?p ?o } }"));

        List<ElementService> services = services(rewritten);
        assertEquals(1, services.size());
        assertEquals(PEOPLE_STORE, services.get(0).getServiceNode().getURI());
        assertFalse(services.get(0).getSilent());
    }

    @Test
    public void testUnauthorizedDataspaceIsRefused()
    {
        when(authorization.authorize(eq(people), eq(endpoint(PEOPLE)), eq(agent), eq(ACL.Read))).thenReturn(null);

        AuthorizationException ex = assertThrows(AuthorizationException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE SILENT <https://people.example/sparql> { ?s ?p ?o } } LIMIT 1")));
        assertEquals(PEOPLE.resolve("sparql"), ex.getAbsolutePath());
        assertEquals(ACL.Read, ex.getMode());
    }

    @Test
    public void testAnonymousAgentIsAskedAboutAsNull()
    {
        ServiceRewriter anonymous = new ServiceRewriter(uri -> people, authorization, new URLValidator(false), null);
        when(authorization.authorize(eq(people), eq(endpoint(PEOPLE)), isNull(), eq(ACL.Read))).thenReturn(null);

        assertThrows(AuthorizationException.class,
            () -> anonymous.rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/sparql> { ?s ?p ?o } }")));
    }

    @Test
    public void testPublicDataspaceIsReachedWithoutAsking()
    {
        Query rewritten = rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE SILENT <https://open.example/sparql> { ?s ?p ?o } }"));

        List<ElementService> services = services(rewritten);
        assertEquals(OPEN_STORE, services.get(0).getServiceNode().getURI());
        assertTrue(services.get(0).getSilent());
        verify(authorization, never()).authorize(any(), any(), any(), any());
    }

    @Test
    public void testDataspaceNamedByAnythingButItsEndpointIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/documents/> { ?s ?p ?o } }")));
        assertThrows(BadRequestException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE <https://open.example/> { ?s ?p ?o } }")));
        verify(authorization, never()).authorize(any(), any(), any(), any());
    }

    @Test
    public void testVariableTargetIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { ?s <http://example.org/endpoint> ?endpoint . SERVICE ?endpoint { ?s ?p ?o } }")));
    }

    @Test
    public void testInternalTargetIsRefused()
    {
        assertThrows(InternalURLException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE SILENT <http://10.0.0.5:3030/admin/> { ?s ?p ?o } }")));
    }

    @Test
    public void testLoopbackTargetIsRefused()
    {
        assertThrows(InternalURLException.class,
            () -> rewriter.rewrite(QueryFactory.create("SELECT * { SERVICE <http://127.0.0.1:3030/admin/> { ?s ?p ?o } }")));
    }

    @Test
    public void testPublicTargetIsLeftAsItIs()
    {
        Query query = QueryFactory.create("SELECT * { SERVICE SILENT <http://93.184.216.34/sparql> { ?s ?p ?o } }");

        Query rewritten = rewriter.rewrite(query);

        List<ElementService> services = services(rewritten);
        assertEquals("http://93.184.216.34/sparql", services.get(0).getServiceNode().getURI());
        assertTrue(services.get(0).getSilent());
        assertEquals(query, rewritten);
    }

    @Test
    public void testQueryWithoutServiceIsUnchanged()
    {
        Query query = QueryFactory.create("SELECT * { ?s ?p ?o } LIMIT 1");

        assertEquals(query, rewriter.rewrite(query));
    }

    @Test
    public void testNestedServicesAreRewritten()
    {
        when(authorization.authorize(eq(people), eq(endpoint(PEOPLE)), eq(agent), eq(ACL.Read))).thenReturn(ModelFactory.createDefaultModel());

        Query rewritten = rewriter.rewrite(QueryFactory.create("""
            SELECT * {
              { SELECT ?s { SERVICE <https://people.example/sparql> { ?s a <http://schema.org/Person> } } }
              FILTER NOT EXISTS { SERVICE <https://open.example/sparql> { ?s <http://schema.org/email> ?e } }
            }"""));

        // the walker of services() stops at a sub-query and a filter, so the serialized query is checked instead
        String serialized = rewritten.toString();
        assertTrue(serialized.contains("<" + PEOPLE_STORE + ">"), serialized);
        assertTrue(serialized.contains("<" + OPEN_STORE + ">"), serialized);
        assertFalse(serialized.contains("people.example"), serialized);
        assertFalse(serialized.contains("open.example"), serialized);
    }

    @Test
    public void testOneRefusalFailsTheWholeQuery()
    {
        when(authorization.authorize(eq(people), eq(endpoint(PEOPLE)), eq(agent), eq(ACL.Read))).thenReturn(null);

        Element pattern = QueryFactory.create("SELECT * { SERVICE <https://open.example/sparql> { ?s ?p ?o } SERVICE <https://people.example/sparql> { ?s ?p ?o } }").getQueryPattern();
        assertThrows(AuthorizationException.class, () -> rewriter.rewrite(QueryFactory.create("SELECT * " + pattern)));
    }

}
