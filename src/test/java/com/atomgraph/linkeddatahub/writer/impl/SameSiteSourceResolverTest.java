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
package com.atomgraph.linkeddatahub.writer.impl;

import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.sun.net.httpserver.HttpServer;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.atomic.AtomicInteger;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.lib.ResourceResolverWrappingURIResolver;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.Xslt30Transformer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * A stylesheet rendered on the server reaches only what the resolver lets it: a URI that is not {@code http(s)}
 * resolves to an empty document, rather than being handed back to Saxon, which would open it itself
 * (formal/xslt, {@code resolve_confined}).
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class SameSiteSourceResolverTest
{

    private static final String STYLESHEET = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>"
        + "<xsl:param name='uri'/>"
        + "<xsl:output method='text'/>"
        + "<xsl:template name='xsl:initial-template'>"
        + "<xsl:value-of select=\"if (doc-available($uri)) then (string(document($uri)), '(empty)')[normalize-space()][1] else 'unavailable'\"/>"
        + "</xsl:template>"
        + "</xsl:stylesheet>";

    private HttpServer server;
    private final AtomicInteger requests = new AtomicInteger();
    private SameSiteSourceResolver resolver;
    private Xslt30Transformer transformer;

    @BeforeEach
    public void setUp() throws Exception
    {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange ->
        {
            requests.incrementAndGet();
            exchange.sendResponseHeaders(404, -1);
            exchange.close();
        });
        server.start();

        resolver = new SameSiteSourceResolver(new PrefixGraphRepository(null), null, true, URI.create("https://localhost:4443/"));
        transformer = new Processor(false).newXsltCompiler().compile(new StreamSource(new StringReader(STYLESHEET))).load30();
        transformer.setResourceResolver(new ResourceResolverWrappingURIResolver(resolver));
    }

    @AfterEach
    public void tearDown()
    {
        server.stop(0);
    }

    private String render(String uri) throws Exception
    {
        transformer.setStylesheetParameters(java.util.Map.of(new QName("uri"), new XdmAtomicValue(uri)));
        StringWriter out = new StringWriter();
        transformer.callTemplate(null, transformer.newSerializer(out));
        return out.toString();
    }

    /**
     * A {@code file:} URI does not read the server's file.
     */
    @Test
    public void testFileIsNotRead() throws Exception
    {
        Path file = Files.createTempFile("secret", ".xml");
        try
        {
            Files.writeString(file, "<secret>server file</secret>");
            assertEquals("(empty)", render(file.toUri().toString()));
        }
        finally
        {
            Files.delete(file);
        }
    }

    /**
     * A {@code jar:http:} URI is not fetched: the request would leave the platform directly, not through the egress proxy.
     */
    @Test
    public void testJarIsNotFetched() throws Exception
    {
        render("jar:http://127.0.0.1:" + server.getAddress().getPort() + "/x.jar!/a.xml");
        assertEquals(0, requests.get());
    }

    /**
     * The empty document stands for the URI it was asked for.
     */
    @Test
    public void testEmptyDocumentKeepsTheURI() throws Exception
    {
        assertNotNull(resolver.resolve("file:///etc/hosts", "https://localhost:4443/"));
        assertEquals("file:///etc/hosts", resolver.resolve("file:///etc/hosts", "https://localhost:4443/").getSystemId());
    }

}
