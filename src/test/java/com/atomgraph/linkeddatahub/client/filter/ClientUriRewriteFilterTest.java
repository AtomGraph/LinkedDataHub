/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.filter;

import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.core.Configuration;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.net.URI;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for {@link ClientUriRewriteFilter}.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ClientUriRewriteFilterTest
{

    private static class StubRequestContext implements ClientRequestContext
    {
        private URI uri;
        private final MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();

        StubRequestContext(URI uri) { this.uri = uri; }

        @Override public URI getUri() { return uri; }
        @Override public void setUri(URI uri) { this.uri = uri; }
        @Override public MultivaluedMap<String, Object> getHeaders() { return headers; }

        @Override public Object getProperty(String name) { throw new UnsupportedOperationException(); }
        @Override public Collection<String> getPropertyNames() { throw new UnsupportedOperationException(); }
        @Override public void setProperty(String name, Object object) { throw new UnsupportedOperationException(); }
        @Override public void removeProperty(String name) { throw new UnsupportedOperationException(); }
        @Override public String getMethod() { throw new UnsupportedOperationException(); }
        @Override public void setMethod(String method) { throw new UnsupportedOperationException(); }
        @Override public MultivaluedMap<String, String> getStringHeaders() { throw new UnsupportedOperationException(); }
        @Override public String getHeaderString(String name) { throw new UnsupportedOperationException(); }
        @Override public Date getDate() { throw new UnsupportedOperationException(); }
        @Override public Locale getLanguage() { throw new UnsupportedOperationException(); }
        @Override public MediaType getMediaType() { throw new UnsupportedOperationException(); }
        @Override public List<MediaType> getAcceptableMediaTypes() { throw new UnsupportedOperationException(); }
        @Override public List<Locale> getAcceptableLanguages() { throw new UnsupportedOperationException(); }
        @Override public Map<String, Cookie> getCookies() { throw new UnsupportedOperationException(); }
        @Override public boolean hasEntity() { throw new UnsupportedOperationException(); }
        @Override public Object getEntity() { throw new UnsupportedOperationException(); }
        @Override public Class<?> getEntityClass() { throw new UnsupportedOperationException(); }
        @Override public Type getEntityType() { throw new UnsupportedOperationException(); }
        @Override public void setEntity(Object entity) { throw new UnsupportedOperationException(); }
        @Override public void setEntity(Object entity, Annotation[] annotations, MediaType mediaType) { throw new UnsupportedOperationException(); }
        @Override public Annotation[] getEntityAnnotations() { throw new UnsupportedOperationException(); }
        @Override public OutputStream getEntityStream() { throw new UnsupportedOperationException(); }
        @Override public void setEntityStream(OutputStream outputStream) { throw new UnsupportedOperationException(); }
        @Override public Client getClient() { throw new UnsupportedOperationException(); }
        @Override public Configuration getConfiguration() { throw new UnsupportedOperationException(); }
        @Override public void abortWith(Response response) { throw new UnsupportedOperationException(); }
    }

    /** Non-matching host: filter must leave the URI untouched. */
    @Test
    public void testNoRewriteForNonMatchingHost() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "http", "nginx", 9443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://other.org/path"));
        filter.filter(ctx);
        assertEquals(URI.create("https://other.org/path"), ctx.getUri());
        assertTrue(ctx.getHeaders().isEmpty());
    }

    /** Exact host match: URI host is rewritten to proxyHost, scheme to proxyScheme. */
    @Test
    public void testRewriteExactHost() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "http", "nginx", 9443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://example.com/path?q=1"));
        filter.filter(ctx);
        assertEquals(URI.create("http://nginx:9443/path?q=1"), ctx.getUri());
        assertEquals("example.com", ctx.getHeaders().getFirst("Host"));
    }

    /** Exact host match with explicit port: Host header must include the original port. */
    @Test
    public void testRewriteExactHostWithPort() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "http", "nginx", 9443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://example.com:4443/path"));
        filter.filter(ctx);
        assertEquals(URI.create("http://nginx:9443/path"), ctx.getUri());
        assertEquals("example.com:4443", ctx.getHeaders().getFirst("Host"));
    }

    /**
     * Subdomain match with same-domain proxy host (production setup):
     * subdomain prefix must be preserved in the rewritten URI so the HTTP client
     * does not reuse a connection established with a different TLS SNI, which
     * would cause nginx to return 421 Misdirected Request.
     */
    @Test
    public void testRewriteSubdomainPreservesSubdomainWithSameDomainProxy() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "https", "example.com", 5443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://admin.example.com/acl/agents/123/"));
        filter.filter(ctx);
        assertEquals(URI.create("https://admin.example.com:5443/acl/agents/123/"), ctx.getUri());
        assertEquals("admin.example.com", ctx.getHeaders().getFirst("Host"));
    }

    /**
     * Subdomain match with internal proxy host (Docker Compose setup):
     * subdomain prefix must NOT be prepended to the proxy hostname — the internal
     * hostname (e.g. "nginx") has no subdomain equivalent. nginx routes via Host header.
     */
    @Test
    public void testRewriteSubdomainWithInternalProxyUsesProxyHostOnly() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "http", "nginx", 9443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://admin.example.com/path"));
        filter.filter(ctx);
        assertEquals(URI.create("http://nginx:9443/path"), ctx.getUri());
        assertEquals("admin.example.com", ctx.getHeaders().getFirst("Host"));
    }

    /** Query string with special characters must survive URI rewrite without decoding. */
    @Test
    public void testQueryStringNotDecoded() throws IOException
    {
        ClientUriRewriteFilter filter = new ClientUriRewriteFilter("example.com", "http", "nginx", 9443);
        StubRequestContext ctx = new StubRequestContext(URI.create("https://example.com/sparql?query=ASK+%7B%7D"));
        filter.filter(ctx);
        assertEquals("query=ASK+%7B%7D", ctx.getUri().getRawQuery());
        assertEquals("example.com", ctx.getHeaders().getFirst("Host"));
    }

}
