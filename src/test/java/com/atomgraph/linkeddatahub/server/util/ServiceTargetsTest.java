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
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.sparql.syntax.ElementService;
import org.apache.jena.sparql.syntax.ElementVisitorBase;
import org.apache.jena.sparql.syntax.ElementWalker;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ServiceTargets}: which <code>SERVICE</code> targets a query may name, and how they are marked
 * with the asking agent. Hosts are IP literals or the mocked dataspaces' names, so no name is resolved.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceTargetsTest
{

    private static final URI PEOPLE = URI.create("https://people.example/");
    private static final String AGENT = "https://admin.example/acl/agents/1/#this";
    private static final Instant NOW = Instant.parse("2026-11-22T12:00:00Z");
    private static final String HOST = "example";

    private static KeyPair secretary;
    private Map<URI, Dataspace> byOrigin;

    @BeforeAll
    public static void key() throws Exception
    {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        secretary = generator.generateKeyPair();
    }

    @BeforeEach
    public void setUp()
    {
        Dataspace people = mock(Dataspace.class);
        when(people.getBaseURI()).thenReturn(PEOPLE);
        byOrigin = Map.of(PEOPLE, people);
    }

    private ServiceTargets anonymous()
    {
        return new ServiceTargets(uri -> byOrigin.get(uri.resolve("/")), new URLValidator(true), HOST, null, null, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private ServiceTargets delegating()
    {
        return new ServiceTargets(uri -> byOrigin.get(uri.resolve("/")), new URLValidator(true), HOST, AGENT, secretary.getPrivate(), Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private static List<String> targets(Query query)
    {
        List<String> targets = new ArrayList<>();
        ElementWalker.walk(query.getQueryPattern(), new ElementVisitorBase()
        {

            @Override
            public void visit(ElementService el)
            {
                targets.add(el.getServiceNode().getURI());
            }

        });
        return targets;
    }

    private static Map<String, String> params(String iri)
    {
        Map<String, String> params = new HashMap<>();
        if (!iri.contains("?")) return params;
        for (String pair : iri.substring(iri.indexOf('?') + 1).split("&"))
            params.put(pair.substring(0, pair.indexOf('=')), URLDecoder.decode(pair.substring(pair.indexOf('=') + 1), StandardCharsets.UTF_8));
        return params;
    }

    @Test
    public void testCanonicalIsTheSharedVector()
    {
        // the Fuseki module's ServiceDelegationTest holds the same vector: change one, change both
        assertEquals("https://people.example/sparql\nhttps://admin.example/acl/agents/1/#this\n1700000000",
            ServiceDelegation.canonical("https://people.example/sparql", "https://admin.example/acl/agents/1/#this", 1700000000L));
    }

    @Test
    public void testADataspaceEndpointIsMarkedWithTheAgentAndSigned() throws Exception
    {
        Query rewritten = delegating().rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/sparql> { ?s ?p ?o } }"));

        String target = targets(rewritten).get(0);
        assertTrue(target.startsWith("https://people.example/sparql?"), target);
        Map<String, String> params = params(target);
        assertEquals(AGENT, params.get(ServiceDelegation.ON_BEHALF_OF));
        assertEquals(Long.toString(NOW.plus(ServiceTargets.MARKER_TTL).getEpochSecond()), params.get(ServiceDelegation.EXPIRES));
        Signature verifier = Signature.getInstance(ServiceDelegation.ALGORITHM);
        verifier.initVerify(secretary.getPublic());
        verifier.update(ServiceDelegation.canonical("https://people.example/sparql", AGENT, NOW.plus(ServiceTargets.MARKER_TTL).getEpochSecond()).getBytes(StandardCharsets.UTF_8));
        assertTrue(verifier.verify(Base64.getUrlDecoder().decode(params.get(ServiceDelegation.SIGNATURE))));
    }

    @Test
    public void testAPublicHttpsTargetIsMarkedTooTheStoreDecidesWhetherToSendIt()
    {
        // the Fuseki module sends the identity only where the server asks for a client certificate
        String target = targets(delegating().rewrite(QueryFactory.create("SELECT * { SERVICE <https://93.184.216.34/sparql> { ?s ?p ?o } }"))).get(0);

        assertEquals(AGENT, params(target).get(ServiceDelegation.ON_BEHALF_OF));
    }

    @Test
    public void testAPlainHttpTargetIsNotMarked()
    {
        String target = targets(delegating().rewrite(QueryFactory.create("SELECT * { SERVICE <http://93.184.216.34/sparql> { ?s ?p ?o } }"))).get(0);

        assertEquals("http://93.184.216.34/sparql", target);
    }

    @Test
    public void testAnAnonymousQueryIsNotMarked()
    {
        Query query = QueryFactory.create("SELECT * { SERVICE <https://people.example/sparql> { ?s ?p ?o } }");

        assertEquals("https://people.example/sparql", targets(anonymous().rewrite(query)).get(0));
    }

    @Test
    public void testAnAuthorsMarkerIsRemovedAndReplaced()
    {
        String forged = "https://people.example/sparql?default-graph-uri=x&ldh-on-behalf-of=https%3A%2F%2Fevil.example%2F%23me&ldh-expires=9999999999&ldh-signature=AAAA";

        assertEquals("https://people.example/sparql?default-graph-uri=x", targets(anonymous().rewrite(QueryFactory.create("SELECT * { SERVICE <" + forged + "> { ?s ?p ?o } }"))).get(0));
        Map<String, String> params = params(targets(delegating().rewrite(QueryFactory.create("SELECT * { SERVICE <" + forged + "> { ?s ?p ?o } }"))).get(0));
        assertEquals(AGENT, params.get(ServiceDelegation.ON_BEHALF_OF));
        assertEquals("x", params.get("default-graph-uri"));
    }

    @Test
    public void testADataspaceNamedByAnythingButItsEndpointIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> delegating().rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/documents/> { ?s ?p ?o } }")));
        assertThrows(BadRequestException.class,
            () -> anonymous().rewrite(QueryFactory.create("SELECT * { SERVICE <https://people.example/> { ?s ?p ?o } }")));
    }

    @Test
    public void testAVariableTargetIsRefused()
    {
        assertThrows(BadRequestException.class,
            () -> anonymous().rewrite(QueryFactory.create("SELECT * { ?s <http://example.org/endpoint> ?endpoint . SERVICE ?endpoint { ?s ?p ?o } }")));
    }

    @Test
    public void testAnInternalTargetIsRefusedEvenWhenInternalUrlsAreAllowed()
    {
        // the validator above allows internal URLs, as the test stacks do; a SERVICE target is refused regardless
        assertThrows(InternalURLException.class,
            () -> delegating().rewrite(QueryFactory.create("SELECT * { SERVICE SILENT <http://10.0.0.5:3030/admin/> { ?s ?p ?o } }")));
        assertThrows(InternalURLException.class,
            () -> anonymous().rewrite(QueryFactory.create("SELECT * { SERVICE <https://127.0.0.1:3030/admin/> { ?s ?p ?o } }")));
    }

    @Test
    public void testAnHttpsTargetOnTheDeploymentsDomainIsNotCheckedByAddress()
    {
        // another deployment under this one's domain - remote.localhost on a local stack - resolves to an internal address
        // here; the store reaches it through the deployment's front door, never at that address
        URLValidator refusing = mock(URLValidator.class);
        when(refusing.validateRemote(any())).thenThrow(new InternalURLException(URI.create("https://remote.example/"), "127.0.0.1"));
        ServiceTargets targets = new ServiceTargets(uri -> byOrigin.get(uri.resolve("/")), refusing, HOST, AGENT, secretary.getPrivate(), Clock.fixed(NOW, ZoneOffset.UTC));

        String target = targets(targets.rewrite(QueryFactory.create("SELECT * { SERVICE <https://remote.example:4443/sparql> { ?s ?p ?o } }"))).get(0);

        assertEquals(AGENT, params(target).get(ServiceDelegation.ON_BEHALF_OF));
        verify(refusing, never()).validateRemote(any());
    }

    @Test
    public void testAPlainHttpTargetOnTheDeploymentsDomainIsCheckedByAddress()
    {
        // the store would call it itself, at whatever address the name has there
        URLValidator refusing = mock(URLValidator.class);
        when(refusing.validateRemote(any())).thenThrow(new InternalURLException(URI.create("http://admin.example:3030/"), "127.0.0.1"));
        ServiceTargets targets = new ServiceTargets(uri -> byOrigin.get(uri.resolve("/")), refusing, HOST, AGENT, secretary.getPrivate(), Clock.fixed(NOW, ZoneOffset.UTC));

        assertThrows(InternalURLException.class,
            () -> targets.rewrite(QueryFactory.create("SELECT * { SERVICE <http://admin.example:3030/admin/> { ?s ?p ?o } }")));
    }

    @Test
    public void testAQueryWithoutServiceIsUnchanged()
    {
        Query query = QueryFactory.create("SELECT * { ?s ?p ?o } LIMIT 1");

        assertEquals(query, delegating().rewrite(query));
    }

    @Test
    public void testNestedServicesAreDecidedAndMarkedToo()
    {
        Query rewritten = delegating().rewrite(QueryFactory.create("""
            SELECT * {
              { SELECT ?s { SERVICE <https://people.example/sparql> { ?s a <http://schema.org/Person> } } }
              FILTER NOT EXISTS { SERVICE <https://93.184.216.34/sparql> { ?s <http://schema.org/email> ?e } }
            }"""));

        // the walker of targets() stops at a sub-query and a filter, so the serialized query is checked instead
        String serialized = rewritten.toString();
        assertTrue(serialized.contains("<https://people.example/sparql?ldh-on-behalf-of="), serialized);
        assertTrue(serialized.contains("<https://93.184.216.34/sparql?ldh-on-behalf-of="), serialized);

        assertThrows(InternalURLException.class, () -> anonymous().rewrite(QueryFactory.create("""
            SELECT * { FILTER NOT EXISTS { SERVICE <http://10.0.0.5:3030/admin/> { ?s ?p ?o } } }""")));
    }

}
