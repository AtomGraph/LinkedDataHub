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

import jakarta.servlet.ServletContext;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import org.apache.commons.io.IOUtils;
import org.apache.jena.rdf.model.Resource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * Tests the local resolution of app-origin stylesheet URLs.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class LocalStylesheetResolverTest
{

    private static final String XSL_CONTENT = "<xsl:stylesheet version=\"3.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"/>";
    private static final String BASE = "https://localhost:4443/static/xsl/layout.xsl";

    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private ServletContext servletContext;
    @Mock(answer = Answers.RETURNS_DEEP_STUBS) private Client client;
    @Mock private Resource app;
    @Mock private Response response;

    private LocalStylesheetResolver resolver;

    @BeforeEach
    public void setUp()
    {
        resolver = new LocalStylesheetResolver(system, servletContext, client);
    }

    @Test
    public void testResolvesAppOriginStaticURLLocally() throws Exception
    {
        String url = "https://localhost:4443/static/xsl/layout.xsl";
        when(system.getAppByOrigin(any(), any(), eq(URI.create(url)))).thenReturn(app);
        when(servletContext.getResourceAsStream("/static/xsl/layout.xsl")).thenReturn(stream(XSL_CONTENT));

        Source source = resolver.resolve(url, "https://localhost:4443/");

        assertInstanceOf(StreamSource.class, source);
        assertEquals(url, source.getSystemId());
        assertEquals(XSL_CONTENT, IOUtils.toString(((StreamSource)source).getInputStream(), StandardCharsets.UTF_8));
    }

    @Test
    public void testResolvesRelativeHrefAgainstHTTPSBase() throws Exception
    {
        String resolved = "https://localhost:4443/static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl";
        when(system.getAppByOrigin(any(), any(), eq(URI.create(resolved)))).thenReturn(app);
        when(servletContext.getResourceAsStream("/static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl")).thenReturn(stream(XSL_CONTENT));

        Source source = resolver.resolve("../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl", BASE);

        assertEquals(resolved, source.getSystemId());
    }

    @Test
    public void testReturnsNullForFileScheme() throws Exception
    {
        assertNull(resolver.resolve("../layout.xsl", "file:/usr/local/tomcat/webapps/ROOT/static/xsl/layout.xsl"));
    }

    @Test
    public void testDelegatesUnknownOriginToRemoteFetch() throws Exception
    {
        String url = "https://packages.example.org/static/xsl/layout.xsl";
        when(system.getAppByOrigin(any(), any(), any())).thenReturn(null);
        when(client.target(URI.create(url)).request().accept(com.atomgraph.client.MediaType.TEXT_XSL_TYPE).get()).thenReturn(response);
        when(response.getStatusInfo()).thenReturn(Response.Status.OK);
        when(response.readEntity(InputStream.class)).thenReturn(stream(XSL_CONTENT));

        Source source = resolver.resolve(url, "https://localhost:4443/");

        assertEquals(url, source.getSystemId());
    }

    private InputStream stream(String content)
    {
        return new ByteArrayInputStream(content.getBytes(StandardCharsets.UTF_8));
    }

}
