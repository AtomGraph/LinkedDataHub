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
package com.atomgraph.linkeddatahub.client.filter;

import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.core.Configuration;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Link;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.NewCookie;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltCompiler;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link JSONGRDDLFilter}.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class JSONGRDDLFilterTest
{

    private static final String STYLESHEET_PATH = "/com/atomgraph/linkeddatahub/client/filter/test-grddl.xsl";

    private static XsltCompiler compiler()
    {
        return new Processor(false).newXsltCompiler();
    }

    /** Concrete subclass parameterised by URI substring marker. Two distinct subclasses below exercise the per-subclass property key. */
    private static class MarkerGRDDLFilter extends JSONGRDDLFilter
    {
        private final String marker;

        MarkerGRDDLFilter(XsltCompiler xc, String marker) throws SaxonApiException
        {
            super(xc, STYLESHEET_PATH);
            this.marker = marker;
        }

        @Override protected boolean isApplicable(URI uri) { return uri.toString().contains(marker); }
        @Override protected URI getJSONURI(URI uri) { return URI.create("https://json.example.org/api?u=" + uri); }
    }

    private static class TestGRDDLFilterA extends MarkerGRDDLFilter
    {
        TestGRDDLFilterA(XsltCompiler xc) throws SaxonApiException { super(xc, "youtube"); }
    }

    private static class TestGRDDLFilterB extends MarkerGRDDLFilter
    {
        TestGRDDLFilterB(XsltCompiler xc) throws SaxonApiException { super(xc, "vimeo"); }
    }

    @Test
    public void testRequestPassesThroughWhenNotApplicable() throws IOException, SaxonApiException
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        URI original = URI.create("https://example.org/page");
        StubRequestContext req = new StubRequestContext(original);

        filter.filter(req);

        assertEquals(original, req.getUri(), "URI must not be rewritten");
        assertTrue(req.getPropertyNames().isEmpty(), "No property must be set");
    }

    @Test
    public void testRequestRedirectsWhenApplicable() throws IOException, SaxonApiException
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        URI original = URI.create("https://www.youtube.com/watch?v=abc");
        StubRequestContext req = new StubRequestContext(original);

        filter.filter(req);

        assertNotEquals(original, req.getUri(), "URI must be redirected");
        assertTrue(req.getUri().toString().startsWith("https://json.example.org/api?u="), "URI must be the JSON endpoint");
        assertEquals(original, req.getProperty(propertyKey(filter)), "Original URI must be stored under the subclass-scoped property");
    }

    @Test
    public void testResponseSkippedWhenPropertyUnset() throws IOException, SaxonApiException
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        StubRequestContext req = new StubRequestContext(URI.create("https://json.example.org/api"));
        StubResponseContext res = new StubResponseContext(MediaType.APPLICATION_JSON_TYPE, "{\"a\":1}");
        InputStream before = res.getEntityStream();

        filter.filter(req, res);

        assertSame(before, res.getEntityStream(), "Entity must not be touched when property is unset");
        assertTrue(res.getHeaders().isEmpty(), "Headers must not be touched when property is unset");
    }

    @Test
    public void testResponseSkippedWhenNotJSON() throws IOException, SaxonApiException
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        URI original = URI.create("https://www.youtube.com/watch?v=abc");
        StubRequestContext req = new StubRequestContext(original);
        filter.filter(req); // sets property
        StubResponseContext res = new StubResponseContext(MediaType.TEXT_HTML_TYPE, "<html/>");
        InputStream before = res.getEntityStream();

        filter.filter(req, res);

        assertSame(before, res.getEntityStream(), "Entity must not be touched for non-JSON responses");
        assertTrue(res.getHeaders().isEmpty(), "Headers must not be touched for non-JSON responses");
    }

    @Test
    public void testResponseSkippedWhenIsApplicableNoLongerHolds() throws IOException, SaxonApiException
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        StubRequestContext req = new StubRequestContext(URI.create("https://json.example.org/api"));
        // Simulate a stale or alien property value under this filter's key — a URI this filter would not handle.
        req.setProperty(propertyKey(filter), URI.create("https://vimeo.com/123"));
        StubResponseContext res = new StubResponseContext(MediaType.APPLICATION_JSON_TYPE, "{\"a\":1}");
        InputStream before = res.getEntityStream();

        filter.filter(req, res);

        assertSame(before, res.getEntityStream(), "Defensive isApplicable re-check must skip non-matching original URIs");
        assertTrue(res.getHeaders().isEmpty(), "Defensive isApplicable re-check must leave headers untouched");
    }

    @Test
    public void testResponseTransformsJSONToRDF() throws Exception
    {
        TestGRDDLFilterA filter = new TestGRDDLFilterA(compiler());
        URI original = URI.create("https://www.youtube.com/watch?v=abc");
        StubRequestContext req = new StubRequestContext(original);
        filter.filter(req); // sets property and redirects
        StubResponseContext res = new StubResponseContext(MediaType.APPLICATION_JSON_TYPE, "{\"title\":\"x\"}");

        filter.filter(req, res);

        assertEquals(com.atomgraph.core.MediaType.APPLICATION_RDF_XML, res.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE), "Content-Type must be set to RDF/XML");
        assertNotNull(res.getHeaders().getFirst(HttpHeaders.CONTENT_LENGTH), "Content-Length must be set");
        String body = new String(res.getEntityStream().readAllBytes(), StandardCharsets.UTF_8);
        assertTrue(body.contains("rdf:RDF"), "Body must be RDF/XML; got: " + body);
        assertTrue(body.contains(original.toString()), "Body must reference original request URI; got: " + body);
        assertTrue(body.contains("{&quot;title&quot;:&quot;x&quot;}") || body.contains("{\"title\":\"x\"}"), "Body must include the JSON payload (escaped or raw); got: " + body);
    }

    /**
     * Two distinct {@link JSONGRDDLFilter} subclasses on one chain. When subclass A's request side matches and
     * stores its property, subclass B's response side must NOT see that property — the per-subclass property
     * key (Option B) is what isolates them.
     */
    @Test
    public void testMultiSubclassPropertyIsolation() throws Exception
    {
        TestGRDDLFilterA filterA = new TestGRDDLFilterA(compiler());
        TestGRDDLFilterB filterB = new TestGRDDLFilterB(compiler());
        URI original = URI.create("https://www.youtube.com/watch?v=abc");
        StubRequestContext req = new StubRequestContext(original);

        filterA.filter(req); // matches youtube → sets property under A's key
        filterB.filter(req); // input is now the JSON endpoint URI; B's isApplicable("vimeo") is false → no-op

        StubResponseContext res = new StubResponseContext(MediaType.APPLICATION_JSON_TYPE, "{\"title\":\"x\"}");

        // Filter B's response side: property under B's key is unset, so it must skip entirely.
        filterB.filter(req, res);
        assertNull(res.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE), "Filter B must not touch headers — its property is unset");
        String beforeBody = new String(((ByteArrayInputStream) res.getEntityStream()).readAllBytes(), StandardCharsets.UTF_8);
        assertEquals("{\"title\":\"x\"}", beforeBody, "Filter B must not touch the entity");

        // Restore JSON entity for filter A.
        res.setEntityStream(new ByteArrayInputStream("{\"title\":\"x\"}".getBytes(StandardCharsets.UTF_8)));

        // Filter A's response side: its property is set and its URI is applicable → must transform.
        filterA.filter(req, res);
        assertEquals(com.atomgraph.core.MediaType.APPLICATION_RDF_XML, res.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE), "Filter A must transform when its property is set");
    }

    /** Reconstructs the per-subclass property key the same way {@link JSONGRDDLFilter} does, for direct stub manipulation. */
    private static String propertyKey(JSONGRDDLFilter filter)
    {
        return "com.atomgraph.linkeddatahub.originalRequestURI." + filter.getClass().getName();
    }

    private static class StubRequestContext implements ClientRequestContext
    {
        private URI uri;
        private final Map<String, Object> properties = new HashMap<>();
        private final MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();

        StubRequestContext(URI uri) { this.uri = uri; }

        @Override public URI getUri() { return uri; }
        @Override public void setUri(URI uri) { this.uri = uri; }
        @Override public Object getProperty(String name) { return properties.get(name); }
        @Override public Collection<String> getPropertyNames() { return properties.keySet(); }
        @Override public void setProperty(String name, Object object) { properties.put(name, object); }
        @Override public void removeProperty(String name) { properties.remove(name); }
        @Override public MultivaluedMap<String, Object> getHeaders() { return headers; }

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

    private static class StubResponseContext implements ClientResponseContext
    {
        private InputStream entityStream;
        private final MediaType mediaType;
        private final MultivaluedMap<String, String> headers = new MultivaluedHashMap<>();

        StubResponseContext(MediaType mediaType, String body)
        {
            this.mediaType = mediaType;
            this.entityStream = body == null ? null : new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8));
        }

        @Override public MediaType getMediaType() { return mediaType; }
        @Override public InputStream getEntityStream() { return entityStream; }
        @Override public void setEntityStream(InputStream input) { this.entityStream = input; }
        @Override public MultivaluedMap<String, String> getHeaders() { return headers; }
        @Override public boolean hasEntity() { return entityStream != null; }

        @Override public int getStatus() { throw new UnsupportedOperationException(); }
        @Override public void setStatus(int code) { throw new UnsupportedOperationException(); }
        @Override public Response.StatusType getStatusInfo() { throw new UnsupportedOperationException(); }
        @Override public void setStatusInfo(Response.StatusType statusInfo) { throw new UnsupportedOperationException(); }
        @Override public String getHeaderString(String name) { throw new UnsupportedOperationException(); }
        @Override public Set<String> getAllowedMethods() { return new HashSet<>(); }
        @Override public Date getDate() { throw new UnsupportedOperationException(); }
        @Override public Locale getLanguage() { throw new UnsupportedOperationException(); }
        @Override public int getLength() { throw new UnsupportedOperationException(); }
        @Override public Map<String, NewCookie> getCookies() { throw new UnsupportedOperationException(); }
        @Override public Date getLastModified() { throw new UnsupportedOperationException(); }
        @Override public EntityTag getEntityTag() { throw new UnsupportedOperationException(); }
        @Override public URI getLocation() { throw new UnsupportedOperationException(); }
        @Override public Set<Link> getLinks() { return new HashSet<>(); }
        @Override public boolean hasLink(String relation) { return false; }
        @Override public Link getLink(String relation) { return null; }
        @Override public Link.Builder getLinkBuilder(String relation) { return null; }
    }

}
