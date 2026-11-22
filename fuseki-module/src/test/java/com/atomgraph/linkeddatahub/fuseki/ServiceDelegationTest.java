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
package com.atomgraph.linkeddatahub.fuseki;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.time.Instant;
import java.util.Base64;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link ServiceDelegation}, the marker's format and check.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceDelegationTest
{

    /** The test vector the platform's signer is checked against too: change one, change both */
    public static final String VECTOR_TARGET = "https://people.example/sparql", VECTOR_AGENT = "https://admin.example/acl/agents/1/#this";
    public static final long VECTOR_EXPIRES = 1700000000L;
    public static final String VECTOR_CANONICAL = "https://people.example/sparql\nhttps://admin.example/acl/agents/1/#this\n1700000000";

    private static KeyPair secretary, other;

    @BeforeAll
    public static void keys() throws Exception
    {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        secretary = generator.generateKeyPair();
        other = generator.generateKeyPair();
    }

    static String mark(String target, String agent, long expires, java.security.PrivateKey key) throws Exception
    {
        Signature signer = Signature.getInstance(ServiceDelegation.ALGORITHM);
        signer.initSign(key);
        signer.update(ServiceDelegation.canonical(target, agent, expires).getBytes(StandardCharsets.UTF_8));
        String signature = Base64.getUrlEncoder().withoutPadding().encodeToString(signer.sign());
        return target + (target.contains("?") ? "&" : "?") + ServiceDelegation.ON_BEHALF_OF + "=" + java.net.URLEncoder.encode(agent, StandardCharsets.UTF_8)
            + "&" + ServiceDelegation.EXPIRES + "=" + expires + "&" + ServiceDelegation.SIGNATURE + "=" + signature;
    }

    @Test
    public void testCanonicalIsTheSharedVector()
    {
        assertEquals(VECTOR_CANONICAL, ServiceDelegation.canonical(VECTOR_TARGET, VECTOR_AGENT, VECTOR_EXPIRES));
    }

    @Test
    public void testAMarkerSignedByTheSecretaryHolds() throws Exception
    {
        long expires = Instant.now().plusSeconds(60).getEpochSecond();
        ServiceDelegation.Marked marked = ServiceDelegation.parse(mark(VECTOR_TARGET, VECTOR_AGENT, expires, secretary.getPrivate())).orElseThrow();

        assertEquals(URI.create(VECTOR_TARGET), marked.target());
        assertEquals(URI.create(VECTOR_AGENT), marked.agent());
        assertTrue(ServiceDelegation.verify(marked, secretary.getPublic(), Instant.now()));
    }

    @Test
    public void testAMarkerSignedByAnotherKeyDoesNot() throws Exception
    {
        long expires = Instant.now().plusSeconds(60).getEpochSecond();
        ServiceDelegation.Marked marked = ServiceDelegation.parse(mark(VECTOR_TARGET, VECTOR_AGENT, expires, other.getPrivate())).orElseThrow();

        assertFalse(ServiceDelegation.verify(marked, secretary.getPublic(), Instant.now()));
    }

    @Test
    public void testAnExpiredMarkerDoesNot() throws Exception
    {
        long expires = Instant.now().minusSeconds(1).getEpochSecond();
        ServiceDelegation.Marked marked = ServiceDelegation.parse(mark(VECTOR_TARGET, VECTOR_AGENT, expires, secretary.getPrivate())).orElseThrow();

        assertFalse(ServiceDelegation.verify(marked, secretary.getPublic(), Instant.now()));
    }

    @Test
    public void testAMarkerMovedToAnotherTargetOrAgentDoesNot() throws Exception
    {
        long expires = Instant.now().plusSeconds(60).getEpochSecond();
        String marked = mark(VECTOR_TARGET, VECTOR_AGENT, expires, secretary.getPrivate());

        ServiceDelegation.Marked moved = ServiceDelegation.parse(marked.replace("people.example", "issues.example")).orElseThrow();
        assertFalse(ServiceDelegation.verify(moved, secretary.getPublic(), Instant.now()));
        ServiceDelegation.Marked impersonated = ServiceDelegation.parse(marked.replace("agents%2F1", "agents%2F2")).orElseThrow();
        assertFalse(ServiceDelegation.verify(impersonated, secretary.getPublic(), Instant.now()));
    }

    @Test
    public void testOtherParametersAreKeptAndSigned() throws Exception
    {
        String target = "https://people.example/sparql?default-graph-uri=https%3A%2F%2Fpeople.example%2Fa%2F&x=1";
        long expires = Instant.now().plusSeconds(60).getEpochSecond();
        ServiceDelegation.Marked marked = ServiceDelegation.parse(mark(target, VECTOR_AGENT, expires, secretary.getPrivate())).orElseThrow();

        assertEquals(URI.create(target), marked.target());
        assertTrue(ServiceDelegation.verify(marked, secretary.getPublic(), Instant.now()));
        assertEquals(target, ServiceDelegation.strip(mark(target, VECTOR_AGENT, expires, secretary.getPrivate())));
    }

    @Test
    public void testNoMarkerIsNothing()
    {
        assertTrue(ServiceDelegation.parse("https://people.example/sparql").isEmpty());
        assertTrue(ServiceDelegation.parse("https://people.example/sparql?x=1").isEmpty());
    }

    @Test
    public void testAPartialOrUnknownMarkerIsRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> ServiceDelegation.parse(VECTOR_TARGET + "?ldh-on-behalf-of=x&ldh-expires=1"));
        assertThrows(IllegalArgumentException.class, () -> ServiceDelegation.parse(VECTOR_TARGET + "?ldh-on-behalf-of=x&ldh-expires=1&ldh-signature=AA&ldh-role=owner"));
        assertThrows(IllegalArgumentException.class, () -> ServiceDelegation.parse(VECTOR_TARGET + "?ldh-on-behalf-of=x&ldh-expires=soon&ldh-signature=AA"));
    }

}
