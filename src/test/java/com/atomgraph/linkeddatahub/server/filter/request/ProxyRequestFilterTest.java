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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Variant;
import java.io.IOException;
import java.net.URI;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link ProxyRequestFilter}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@RunWith(MockitoJUnitRunner.class)
public class ProxyRequestFilterTest
{

    @Mock private ContainerRequestContext requestContext;
    @Mock private Request request;
    @Mock private com.atomgraph.linkeddatahub.Application system;

    private ProxyRequestFilter filter;

    @Before
    public void setUp()
    {
        filter = new ProxyRequestFilter();
        filter.mediaTypes = new MediaTypes();
        filter.request = request;
        filter.system = system;
        when(system.getSupportedLanguages()).thenReturn(Collections.emptyList());
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

    /** No acceptable RDF/SPARQL variant — filter must throw 406. */
    @Test(expected = NotAcceptableException.class)
    public void testNullVariantThrowsNotAcceptable() throws IOException
    {
        when(requestContext.getProperty(AC.uri.getURI()))
            .thenReturn(URI.create("http://example.org/resource"));
        when(requestContext.getAcceptableMediaTypes())
            .thenReturn(List.of(MediaType.WILDCARD_TYPE));
        when(request.selectVariant(anyList())).thenReturn(null);
        filter.filter(requestContext);
    }

}
