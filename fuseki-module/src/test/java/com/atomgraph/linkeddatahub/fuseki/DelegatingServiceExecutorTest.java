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

import com.sun.net.httpserver.HttpsConfigurator;
import com.sun.net.httpserver.HttpsExchange;
import com.sun.net.httpserver.HttpsParameters;
import com.sun.net.httpserver.HttpsServer;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509ExtendedTrustManager;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.QueryExecException;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.ResultSetFormatter;
import org.apache.jena.sparql.service.ServiceExecutorRegistry;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link DelegatingServiceExecutor} against two stub SPARQL endpoints over TLS: one that asks for a
 * client certificate (as LinkedDataHub's nginx does) and one that does not (as a public SPARQL service). Both are reached
 * as this deployment's origins, through their own "internal proxy" address, with the original <code>Host</code>. The
 * keystores are made by <code>keytool</code> for the run.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DelegatingServiceExecutorTest
{

    static final String PASSWORD = "changeit", AGENT = "https://admin.localhost/acl/agents/1/#this";
    static final String RESULT = "{\"head\":{\"vars\":[\"s\"]},\"results\":{\"bindings\":[{\"s\":{\"type\":\"uri\",\"value\":\"https://people.test/a/#this\"}}]}}";

    @TempDir static Path dir;
    static KeyStore secretary;
    static X509Certificate serverCert;
    static Stub asks, anonymous;

    /** What a stub saw of each request. */
    record Seen(String uri, String onBehalfOf, String host, String clientCertificate) { }

    static final class Stub
    {
        final HttpsServer server;
        final List<Seen> seen = new CopyOnWriteArrayList<>();

        Stub(SSLContext context, boolean wantClientAuth) throws Exception
        {
            server = HttpsServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            server.setHttpsConfigurator(new HttpsConfigurator(context)
            {
                @Override
                public void configure(HttpsParameters params)
                {
                    SSLParameters ssl = getSSLContext().getDefaultSSLParameters();
                    ssl.setWantClientAuth(wantClientAuth);
                    params.setSSLParameters(ssl);
                }
            });
            server.createContext("/", exchange ->
            {
                String peer = null;
                try
                {
                    peer = ((X509Certificate)((HttpsExchange)exchange).getSSLSession().getPeerCertificates()[0]).getSubjectX500Principal().getName();
                }
                catch (SSLPeerUnverifiedException ex) { /* anonymous */ }
                seen.add(new Seen(exchange.getRequestURI().toString(), exchange.getRequestHeaders().getFirst("On-Behalf-Of"),
                    exchange.getRequestHeaders().getFirst("Host"), peer));
                byte[] body = "HEAD".equals(exchange.getRequestMethod()) ? new byte[0] : RESULT.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().add("Content-Type", "application/sparql-results+json");
                exchange.sendResponseHeaders(200, "HEAD".equals(exchange.getRequestMethod()) ? -1 : body.length);
                exchange.getResponseBody().write(body);
                exchange.close();
            });
            server.start();
        }

        int port() { return server.getAddress().getPort(); }

        List<Seen> queries() { return seen.stream().filter(s -> s.uri().contains("query=")).toList(); }
    }

    static void keytool(String... args) throws Exception
    {
        List<String> command = new java.util.ArrayList<>(List.of(Path.of(System.getProperty("java.home"), "bin", "keytool").toString()));
        command.addAll(List.of(args));
        Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        assertEquals(0, process.waitFor(), output);
    }

    static KeyStore load(Path path) throws Exception
    {
        KeyStore store = KeyStore.getInstance("PKCS12");
        try (InputStream in = Files.newInputStream(path))
        {
            store.load(in, PASSWORD.toCharArray());
        }
        return store;
    }

    @BeforeAll
    public static void start() throws Exception
    {
        org.apache.jena.sys.JenaSystem.init();
        keytool("-genkeypair", "-alias", "secretary", "-keyalg", "RSA", "-keysize", "2048", "-dname", "CN=secretary", "-validity", "2",
            "-keystore", dir.resolve("secretary.p12").toString(), "-storetype", "PKCS12", "-storepass", PASSWORD);
        keytool("-genkeypair", "-alias", "server", "-keyalg", "RSA", "-keysize", "2048", "-dname", "CN=localhost", "-ext", "SAN=dns:localhost",
            "-validity", "2", "-keystore", dir.resolve("server.p12").toString(), "-storetype", "PKCS12", "-storepass", PASSWORD);
        secretary = load(dir.resolve("secretary.p12"));
        KeyStore server = load(dir.resolve("server.p12"));
        serverCert = (X509Certificate)server.getCertificate("server");

        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(server, PASSWORD.toCharArray());
        SSLContext context = SSLContext.getInstance("TLS");
        context.init(kmf.getKeyManagers(), new TrustManager[] { new AnyClient() }, null); // the stub reads whatever certificate it is shown
        asks = new Stub(context, true);
        anonymous = new Stub(context, false);
    }

    @AfterAll
    public static void stop()
    {
        asks.server.stop(0);
        anonymous.server.stop(0);
    }

    @BeforeEach
    public void clear()
    {
        asks.seen.clear();
        anonymous.seen.clear();
    }

    static Routes routes(Stub stub) throws Exception
    {
        return new Routes("people.test", "127.0.0.1", stub.port(), secretary, PASSWORD.toCharArray(), serverCert);
    }

    static String marked(String target, long expiresIn) throws Exception
    {
        return ServiceDelegationTest.mark(target, AGENT, Instant.now().plusSeconds(expiresIn).getEpochSecond(), (PrivateKey)secretary.getKey("secretary", PASSWORD.toCharArray()));
    }

    static int select(String query, DelegatingServiceExecutor executor)
    {
        ServiceExecutorRegistry registry = ServiceExecutorRegistry.createFrom(ServiceExecutorRegistry.standardRegistry());
        registry.addSingleLink(executor);
        try (QueryExecution qe = QueryExecutionFactory.create(query, DatasetFactory.create()))
        {
            ServiceExecutorRegistry.set(qe.getContext(), registry);
            return ResultSetFormatter.consume(qe.execSelect());
        }
    }

    static DelegatingServiceExecutor executor(Stub stub) throws Exception
    {
        DelegatingServiceExecutor.Delegation delegation = new DelegatingServiceExecutor.Delegation(secretary.getCertificate("secretary").getPublicKey(), routes(stub));
        return new DelegatingServiceExecutor(() -> delegation, Clock.systemUTC());
    }

    @Test
    public void testAnEndpointThatAsksIsCalledAsTheSecretaryOnTheAgentsBehalf() throws Exception
    {
        assertEquals(1, select("SELECT * { SERVICE <" + marked("https://people.test:4443/sparql", 60) + "> { ?s ?p ?o } }", executor(asks)));

        Seen query = asks.queries().get(0);
        assertEquals(AGENT, query.onBehalfOf());
        assertEquals("people.test:4443", query.host(), "the original origin, for the proxy to route by");
        assertEquals("CN=secretary", query.clientCertificate());
        assertTrue(query.uri().startsWith("/sparql?query="), query.uri());
        assertFalse(query.uri().contains("ldh-"), "the marker is not sent on: " + query.uri());
    }

    @Test
    public void testAnEndpointThatDoesNotAskIsCalledAnonymously() throws Exception
    {
        // the route's anonymous call goes through Jena's own client, which does not trust the stub's certificate; SILENT
        // keeps the query alive, and what the stub saw is the probe alone: no certificate, no agent
        select("SELECT * { SERVICE SILENT <" + marked("https://people.test:4443/sparql", 60) + "> { ?s ?p ?o } }", executor(anonymous));

        assertFalse(anonymous.seen.isEmpty(), "the probe reached the stub");
        for (Seen seen : anonymous.seen)
        {
            assertNull(seen.onBehalfOf(), "no agent is announced to an endpoint that does not ask: " + seen);
            assertNull(seen.clientCertificate(), "no certificate is shown to an endpoint that does not ask: " + seen);
            assertFalse(seen.uri().contains("ldh-"), seen.uri());
        }
    }

    @Test
    public void testAForgedMarkerFailsTheQueryEvenWhenSilent() throws Exception
    {
        String forged = marked("https://people.test:4443/sparql", 60).replace("agents%2F1", "agents%2F2");

        assertThrows(QueryExecException.class, () -> select("SELECT * { SERVICE SILENT <" + forged + "> { ?s ?p ?o } }", executor(asks)));
        assertTrue(asks.queries().isEmpty(), "nothing is sent for a forged marker");
    }

    @Test
    public void testAnExpiredMarkerFailsTheQuery() throws Exception
    {
        String expired = marked("https://people.test:4443/sparql", -1);

        assertThrows(QueryExecException.class, () -> select("SELECT * { SERVICE <" + expired + "> { ?s ?p ?o } }", executor(asks)));
        assertTrue(asks.queries().isEmpty());
    }

    @Test
    public void testAPartialMarkerFailsTheQuery() throws Exception
    {
        assertThrows(QueryExecException.class,
            () -> select("SELECT * { SERVICE <https://people.test:4443/sparql?ldh-on-behalf-of=" + AGENT + "> { ?s ?p ?o } }", executor(asks)));
    }

    @Test
    public void testWithoutAKeyTheMarkerIsDroppedNotSentOn() throws Exception
    {
        DelegatingServiceExecutor unconfigured = new DelegatingServiceExecutor(() -> null, Clock.systemUTC());
        // the target is the stub by its own address: unconfigured, nothing routes it, and Jena's client does not trust it
        String target = "https://127.0.0.1:" + asks.port() + "/sparql";

        select("SELECT * { SERVICE SILENT <" + marked(target, 60) + "> { ?s ?p ?o } }", unconfigured);
        for (Seen seen : asks.seen) assertFalse(seen.uri().contains("ldh-"), seen.uri());
    }

    @Test
    public void testAKeystoreNotThereYetFailsTheCallNotTheServer() throws Exception
    {
        // the platform makes the secretary's keystore and starts after the store: until it is there, a marked call fails
        // by name, and the next call reads it again
        DelegationModule.Loaded loaded = new DelegationModule.Loaded(name -> switch (name)
        {
            case "LDH_DELEGATION_KEYSTORE" -> dir.resolve("not-yet.p12").toString();
            case "LDH_DELEGATION_KEYSTORE_PASSWORD_FILE" -> dir.resolve("not-yet.txt").toString();
            default -> "x";
        });
        DelegatingServiceExecutor waiting = new DelegatingServiceExecutor(loaded, Clock.systemUTC());

        QueryExecException ex = assertThrows(QueryExecException.class,
            () -> select("SELECT * { SERVICE <" + marked("https://people.test:4443/sparql", 60) + "> { ?s ?p ?o } }", waiting));
        assertTrue(ex.getMessage().contains("cannot be called on behalf of its agent yet"), ex.getMessage());
        assertTrue(asks.seen.isEmpty());
    }

    /** A server-side trust manager that accepts any client certificate, so the stub can read it. */
    static final class AnyClient extends X509ExtendedTrustManager
    {
        @Override public void checkClientTrusted(X509Certificate[] chain, String authType, Socket socket) { }
        @Override public void checkClientTrusted(X509Certificate[] chain, String authType, SSLEngine engine) { }
        @Override public void checkClientTrusted(X509Certificate[] chain, String authType) { }
        @Override public void checkServerTrusted(X509Certificate[] chain, String authType, Socket socket) { }
        @Override public void checkServerTrusted(X509Certificate[] chain, String authType, SSLEngine engine) { }
        @Override public void checkServerTrusted(X509Certificate[] chain, String authType) { }
        @Override public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
    }

}
