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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.ResourceFactory;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.ResultSetFactory;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.sparql.resultset.SPARQLResult;
import org.glassfish.jersey.internal.MapPropertiesDelegate;
import org.glassfish.jersey.server.ContainerRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link ProxyRequestFilter}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class ProxyRequestFilterTest
{

    @Mock private ContainerRequestContext requestContext;
    @Mock private Request request;
    @Mock private HttpHeaders httpHeaders;
    @Mock private com.atomgraph.linkeddatahub.Application system;

    private ProxyRequestFilter filter;

    @BeforeEach
    public void setUp()
    {
        filter = new ProxyRequestFilter();
        filter.mediaTypes = new MediaTypes();
        filter.request = request;
        filter.httpHeaders = httpHeaders;
        filter.system = system;
    }

    /** No proxy properties set — filter must be a no-op. */
    @Test
    public void testNonProxyRequestSkipsFilter() throws IOException
    {
        filter.filter(requestContext);
        verify(request, never()).selectVariant(anyList());
        verify(requestContext, never()).abortWith(any());
    }

    /** Client explicitly accepts text/html — filter must return early (app shell). */
    @Test
    public void testHtmlAcceptReturnsEarly() throws IOException
    {
        when(requestContext.getProperty(AC.uri.getURI()))
            .thenReturn(URI.create("http://example.org/resource"));
        when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.TEXT_HTML_TYPE));
        when(system.isEnableLinkedDataProxy()).thenReturn(true);
        filter.filter(requestContext);
        verify(request, never()).selectVariant(anyList());
        verify(requestContext, never()).abortWith(any());
    }

    /** Client explicitly accepts application/xhtml+xml — filter must return early (app shell). */
    @Test
    public void testXhtmlAcceptReturnsEarly() throws IOException
    {
        when(requestContext.getProperty(AC.uri.getURI()))
            .thenReturn(URI.create("http://example.org/resource"));
        when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.APPLICATION_XHTML_XML_TYPE));
        when(system.isEnableLinkedDataProxy()).thenReturn(true);
        filter.filter(requestContext);
        verify(request, never()).selectVariant(anyList());
        verify(requestContext, never()).abortWith(any());
    }

    /** Proxy disabled: an external target is refused even when the client prefers text/html, rather than rendering the app shell. */
    @Test
    public void testHtmlAcceptForbiddenWhenProxyDisabled()
    {
        PrefixGraphRepository repository = mock(PrefixGraphRepository.class);
        when(requestContext.getProperty(AC.uri.getURI()))
            .thenReturn(URI.create("http://dbpedia.org/resource/Banjoist"));
        lenient().when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.TEXT_HTML_TYPE));
        when(system.getRepository()).thenReturn(repository);
        assertThrows(ForbiddenException.class, () -> filter.filter(requestContext));
        verify(requestContext, never()).abortWith(any());
    }

    /** Proxy disabled: one of this instance's dataspaces still gets the app shell. */
    @Test
    public void testHtmlAcceptReturnsEarlyForDataspaceWhenProxyDisabled() throws IOException
    {
        URI targetURI = URI.create("https://admin.localhost:4443/doc");
        when(requestContext.getProperty(AC.uri.getURI())).thenReturn(targetURI);
        when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.TEXT_HTML_TYPE));
        when(system.matchApp(targetURI)).thenReturn(ResourceFactory.createResource("https://admin.localhost:4443/"));
        filter.filter(requestContext);
        verify(requestContext, never()).abortWith(any());
    }

    /** Proxy disabled: a mapped document still gets the app shell, matched without its fragment. */
    @Test
    public void testHtmlAcceptReturnsEarlyForMappedWhenProxyDisabled() throws IOException
    {
        PrefixGraphRepository repository = mock(PrefixGraphRepository.class);
        when(requestContext.getProperty(AC.uri.getURI()))
            .thenReturn(URI.create("https://w3id.org/atomgraph/linkeddatahub#SelectChildren"));
        when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.TEXT_HTML_TYPE));
        when(system.getRepository()).thenReturn(repository);
        when(repository.isMapped("https://w3id.org/atomgraph/linkeddatahub")).thenReturn(true);
        filter.filter(requestContext);
        verify(requestContext, never()).abortWith(any());
    }

    /**
     * The filter answering, after the upstream has, a request that accepts the given media type: a real request, so
     * the content negotiation is Jersey's rather than a stub's.
     */
    private ProxyRequestFilter accepting(String accept)
    {
        ContainerRequest containerRequest = new ContainerRequest(URI.create("https://localhost:4443/"),
            URI.create("https://localhost:4443/?uri=https%3A%2F%2Fremote.example%2Fsparql"), "GET", null, new MapPropertiesDelegate(), null);
        containerRequest.header(HttpHeaders.ACCEPT, accept);
        filter.request = containerRequest;
        filter.httpHeaders = containerRequest; // Jersey's container request is also the request's HttpHeaders
        return filter;
    }

    /** An upstream that answered an ASK: the boolean is served, not read as a result set (which throws) */
    @Test
    public void testBooleanResultIsServedAsBoolean()
    {
        for (String accept : List.of("application/sparql-results+json", "application/sparql-results+xml"))
            try (Response response = accepting(accept).getResponse(new SPARQLResult(true), Response.Status.OK))
            {
                assertEquals(200, response.getStatus(), accept);
                assertTrue(response.getMediaType().isCompatible(MediaType.valueOf(accept)), response.getMediaType().toString());
                SPARQLResult entity = (SPARQLResult)response.getEntity();
                assertTrue(entity.isBoolean() && entity.getBooleanResult(), accept);
            }
    }

    @Test
    public void testBooleanResultTagsTellTrueFromFalse()
    {
        String trueTag, falseTag;
        try (Response response = accepting("application/sparql-results+json").getResponse(new SPARQLResult(true), Response.Status.OK)) { trueTag = response.getHeaderString(HttpHeaders.ETAG); }
        try (Response response = accepting("application/sparql-results+json").getResponse(new SPARQLResult(false), Response.Status.OK)) { falseTag = response.getHeaderString(HttpHeaders.ETAG); }
        assertNotEquals(trueTag, falseTag);
    }

    /** Jena has no boolean encoding in Protobuf, and HTML has no writer for a boolean: neither is offered */
    @Test
    public void testBooleanResultNotOfferedInFormatsWithoutABooleanWriter()
    {
        assertThrows(NotAcceptableException.class, () -> accepting("application/x-protobuf+sparql-results").getResponse(new SPARQLResult(true), Response.Status.OK));
        assertThrows(NotAcceptableException.class, () -> accepting("text/html").getResponse(new SPARQLResult(true), Response.Status.OK));
    }

    @Test
    public void testResultSetResultIsServedAsResultSet()
    {
        ResultSetRewindable rows = ResultSetFactory.copyResults(QueryExecutionFactory.create("SELECT ?x WHERE { VALUES ?x { 1 2 } }", ModelFactory.createDefaultModel()).execSelect());
        try (Response response = accepting("application/sparql-results+json").getResponse(new SPARQLResult(rows), Response.Status.OK))
        {
            assertEquals(200, response.getStatus());
            assertTrue(response.getEntity() instanceof ResultSetRewindable, "the result set arm keeps its own response");
        }
    }

    /**
     * An upstream's Vary used to replace the proxy's own, so a cache stored the proxied RDF under the bare URL and
     * served it to the next browser navigation: Rotten Tomatoes sends Cache-Control: max-age=300 with Vary: Accept-Encoding.
     */
    @Test
    public void testUpstreamVaryDoesNotReplaceAccept()
    {
        Response local = Response.ok().header(HttpHeaders.VARY, "Accept, Accept-Language").build();
        Response upstream = Response.ok().header(HttpHeaders.VARY, "Accept-Encoding").header(HttpHeaders.CACHE_CONTROL, "max-age=300").build();

        try (Response response = filter.overlayHeaders(local, upstream, true))
        {
            assertEquals("Accept, Accept-Language, Accept-Encoding", response.getHeaderString(HttpHeaders.VARY));
            assertEquals("max-age=300", response.getHeaderString(HttpHeaders.CACHE_CONTROL), "Cache-Control is still forwarded");
        }
    }

    /** The raw branch stamps no Vary of its own, and still chose this body by Accept */
    @Test
    public void testRawResponseVariesOnAccept()
    {
        try (Response response = filter.overlayHeaders(Response.ok().build(), Response.ok().build(), true))
        {
            assertEquals("Accept", response.getHeaderString(HttpHeaders.VARY));
        }
    }

    /** A body relayed byte for byte, as served or as an error, is the origin's bytes on this origin: sandboxed */
    @Test
    public void testRelayedBytesAreSandboxed()
    {
        for (Response.Status status : List.of(Response.Status.OK, Response.Status.NOT_FOUND))
        {
            Response upstream = mock(Response.class);
            when(upstream.getStatus()).thenReturn(status.getStatusCode());
            when(upstream.getStatusInfo()).thenReturn(status);
            when(upstream.getMediaType()).thenReturn(MediaType.valueOf("image/svg+xml"));
            when(upstream.readEntity(InputStream.class)).thenReturn(new ByteArrayInputStream("<svg/>".getBytes(StandardCharsets.UTF_8)));

            try (Response response = filter.getResponse(upstream, URI.create("https://remote.example/file"), "GET", List.of(MediaType.WILDCARD_TYPE)))
            {
                assertEquals(status.getStatusCode(), response.getStatus());
                assertEquals("default-src 'none'; sandbox", response.getHeaderString("Content-Security-Policy"), status + " relayed without the sandbox policy");
            }
        }
    }

    @Test
    public void testMergeVary()
    {
        assertEquals("Accept", ProxyRequestFilter.mergeVary(null, null));
        assertEquals("Accept, Origin", ProxyRequestFilter.mergeVary("accept", "Origin"), "field names are case-insensitive");
        assertEquals("Accept, Accept-Language, Accept-Encoding", ProxyRequestFilter.mergeVary("Accept,Accept-Language", " Accept-Encoding , accept-language"));
        assertEquals("*", ProxyRequestFilter.mergeVary("Accept", "*"));
    }

    /** An authenticated caller proxying another origin: no certificate, no delegation */
    @Test
    public void testExternalOriginNotDelegated() throws IOException
    {
        for (AgentContext agentContext : List.of(idTokenContext(), mock(WebIDSecurityContext.class)))
        {
            Client certClient = mock(Client.class), noCertClient = mock(Client.class);
            WebTarget target = proxy(URI.create("https://remote.example/doc"), agentContext, false, certClient, noCertClient);

            verify(noCertClient).target(any(URI.class));
            verifyNoInteractions(certClient);
            verify(target, never()).register(any(Object.class));
        }
    }

    /** An ID token caller proxying a dataspace: the certificate, and the token delegated */
    @Test
    public void testDataspaceOriginDelegatesIDToken() throws IOException
    {
        Client certClient = mock(Client.class), noCertClient = mock(Client.class);
        WebTarget target = proxy(URI.create("https://admin.localhost:4443/doc"), idTokenContext(), true, certClient, noCertClient);

        verify(certClient).target(any(URI.class));
        verifyNoInteractions(noCertClient);
        verify(target).register(isA(IDTokenDelegationFilter.class));
        verify(target, never()).register(isA(WebIDDelegationFilter.class));
    }

    /** A WebID caller proxying a dataspace: the certificate, and the agent named in On-Behalf-Of */
    @Test
    public void testDataspaceOriginDelegatesWebID() throws IOException
    {
        Client certClient = mock(Client.class), noCertClient = mock(Client.class);
        WebTarget target = proxy(URI.create("https://admin.localhost:4443/doc"), mock(WebIDSecurityContext.class), true, certClient, noCertClient);

        verify(certClient).target(any(URI.class));
        verify(target).register(isA(WebIDDelegationFilter.class));
        verify(target, never()).register(isA(IDTokenDelegationFilter.class));
    }

    @Test
    public void testAnonymousNotDelegated() throws IOException
    {
        Client certClient = mock(Client.class), noCertClient = mock(Client.class);
        WebTarget target = proxy(URI.create("https://admin.localhost:4443/doc"), null, true, certClient, noCertClient);

        verifyNoInteractions(certClient);
        verify(target, never()).register(any(Object.class));
    }

    /**
     * A write to another origin is delegated, and the GET a 303 continues it as is a read of that origin: it goes out
     * with no certificate and no delegation. It goes out at all although the first hop consumed the request's entity,
     * whose closed stream throws when asked again whether there is one.
     */
    @Test
    public void testSeeOtherAfterForeignWriteGoesOutAnonymous() throws IOException
    {
        URI first = URI.create("https://remote.example/see-other"), second = URI.create("https://remote.example/doc");
        WebIDSecurityContext agentContext = mock(WebIDSecurityContext.class);
        Agent agent = mock(Agent.class);
        when(agentContext.getAgent()).thenReturn(agent);

        when(requestContext.getProperty(AC.uri.getURI())).thenReturn(first);
        when(requestContext.getProperty(AgentContext.class.getCanonicalName())).thenReturn(agentContext);
        when(requestContext.getAcceptableMediaTypes()).thenReturn(List.of(MediaType.valueOf("application/n-triples")));
        when(requestContext.getMethod()).thenReturn("POST");
        when(requestContext.hasEntity()).thenReturn(true).thenThrow(new ProcessingException(new IOException("Stream closed")));
        when(requestContext.getEntityStream()).thenReturn(new ByteArrayInputStream(new byte[0]));
        when(requestContext.getMediaType()).thenReturn(MediaType.valueOf("application/n-triples"));
        UriInfo uriInfo = mock(UriInfo.class);
        when(uriInfo.getRequestUri()).thenReturn(URI.create("https://localhost:4443/"));
        when(requestContext.getUriInfo()).thenReturn(uriInfo);

        when(system.isEnableLinkedDataProxy()).thenReturn(true);
        when(system.getURLValidator()).thenReturn(mock(URLValidator.class));
        Client certClient = mock(Client.class), noCertClient = mock(Client.class);
        when(system.getExternalClient()).thenReturn(certClient);
        when(system.getExternalNoCertClient()).thenReturn(noCertClient);

        WebTarget writeTarget = mock(WebTarget.class), readTarget = mock(WebTarget.class);
        Invocation.Builder writeBuilder = mock(Invocation.Builder.class), readBuilder = mock(Invocation.Builder.class);
        when(certClient.target(first)).thenReturn(writeTarget);
        when(noCertClient.target(second)).thenReturn(readTarget);
        for (WebTarget target : List.of(writeTarget, readTarget)) when(target.property(anyString(), any())).thenReturn(target);
        when(writeTarget.request()).thenReturn(writeBuilder);
        when(readTarget.request()).thenReturn(readBuilder);
        for (Invocation.Builder builder : List.of(writeBuilder, readBuilder))
        {
            when(builder.accept(any(MediaType[].class))).thenReturn(builder);
            when(builder.header(anyString(), any())).thenReturn(builder);
        }
        Response seeOther = mock(Response.class);
        when(seeOther.getStatus()).thenReturn(303);
        when(seeOther.getHeaderString(HttpHeaders.LOCATION)).thenReturn(second.toString());
        when(writeBuilder.method(eq("POST"), any(Entity.class))).thenReturn(seeOther);
        when(readBuilder.method("GET")).thenThrow(new ProcessingException("upstream not reachable in the test"));

        assertThrows(BadGatewayException.class, () -> filter.filter(requestContext));

        verify(writeTarget).register(isA(WebIDDelegationFilter.class));
        verify(readBuilder).method("GET");
        verify(certClient, never()).target(second);
        verify(readTarget, never()).register(any(Object.class));
    }

    /**
     * Runs the filter over a proxied GET whose upstream request fails, and returns the target it went to.
     */
    private WebTarget proxy(URI targetURI, AgentContext agentContext, boolean isDataspace, Client certClient, Client noCertClient) throws IOException
    {
        reset(requestContext, system);
        lenient().when(requestContext.getProperty(AC.uri.getURI())).thenReturn(targetURI);
        lenient().when(requestContext.getProperty(AgentContext.class.getCanonicalName())).thenReturn(agentContext);
        lenient().when(requestContext.getAcceptableMediaTypes()).thenReturn(List.of(MediaType.valueOf("application/n-triples")));
        lenient().when(requestContext.getMethod()).thenReturn("GET");
        UriInfo uriInfo = mock(UriInfo.class);
        lenient().when(uriInfo.getBaseUri()).thenReturn(URI.create("https://localhost:4443/"));
        lenient().when(requestContext.getUriInfo()).thenReturn(uriInfo);

        lenient().when(system.getRepository()).thenReturn(mock(PrefixGraphRepository.class));
        lenient().when(system.matchApp(targetURI)).thenReturn(isDataspace ? ResourceFactory.createResource("https://admin.localhost:4443/") : null);
        lenient().when(system.isEnableLinkedDataProxy()).thenReturn(true);
        lenient().when(system.getURLValidator()).thenReturn(mock(URLValidator.class));
        lenient().when(system.getExternalClient()).thenReturn(certClient);
        lenient().when(system.getExternalNoCertClient()).thenReturn(noCertClient);

        WebTarget target = mock(WebTarget.class);
        Invocation.Builder builder = mock(Invocation.Builder.class);
        lenient().when(certClient.target(any(URI.class))).thenReturn(target);
        lenient().when(noCertClient.target(any(URI.class))).thenReturn(target);
        lenient().when(target.property(anyString(), any())).thenReturn(target);
        lenient().when(target.request()).thenReturn(builder);
        lenient().when(builder.accept(any(MediaType[].class))).thenReturn(builder);
        lenient().when(builder.header(anyString(), any())).thenReturn(builder);
        lenient().when(builder.method("GET")).thenThrow(new ProcessingException("upstream not reachable in the test"));

        assertThrows(BadGatewayException.class, () -> filter.filter(requestContext));
        return target;
    }

    private static IDTokenSecurityContext idTokenContext()
    {
        IDTokenSecurityContext context = mock(IDTokenSecurityContext.class);
        lenient().when(context.getJWTToken()).thenReturn("header.payload.signature");
        return context;
    }

}
