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
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.net.URI;
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
    @Mock private com.atomgraph.linkeddatahub.Application system;

    private ProxyRequestFilter filter;

    @BeforeEach
    public void setUp()
    {
        filter = new ProxyRequestFilter();
        filter.mediaTypes = new MediaTypes();
        filter.request = request;
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
        filter.filter(requestContext);
        verify(request, never()).selectVariant(anyList());
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

}
