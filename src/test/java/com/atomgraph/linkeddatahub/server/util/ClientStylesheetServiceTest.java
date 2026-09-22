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

import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import javax.xml.parsers.DocumentBuilderFactory;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.w3c.dom.Document;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.RETURNS_DEEP_STUBS;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * The compiler request decides what the browser runs, so these pin its shape for the stock entry and
 * for a deployment's own: which modules travel, under which names, and where the packages land in them.
 * No compiler is involved - the request is composed, not sent.
 */
public class ClientStylesheetServiceTest
{

    private static final URI PACKAGE = URI.create("https://packages.example.org/pkg/#this");

    @TempDir
    Path sefRoot;

    @Test
    public void testStockEntryComposesItself() throws Exception
    {
        ClientStylesheetService service = service(resource("xsl/stock/client.xsl"));
        assertTrue(service.isStockEntry());

        JsonObject request = service.compose(List.of(packageURI()));

        Document entry = parse(request.getString("entry"));
        assertEquals(List.of("hooks.xsl", "client/hooks.xsl", "pkg-0.xsl", "common.xsl"), hrefs(entry));
        assertEquals(List.of("pkg-0.xsl"), names(request));
    }

    @Test
    public void testDeploymentEntryComposesTheStockModuleItImports() throws Exception
    {
        ClientStylesheetService service = service(resource("xsl/site/client.xsl"));
        assertFalse(service.isStockEntry());

        JsonObject request = service.compose(List.of(packageURI()));

        // the entry keeps its own rules and imports the composed stock module instead of the stock file
        Document entry = parse(request.getString("entry"));
        assertEquals(List.of(ClientStylesheetService.COMPOSED_STOCK_MODULE, "site-0.xsl"), hrefs(entry));
        assertEquals(1, entry.getElementsByTagNameNS(StylesheetComposer.XSL_NS, "template").getLength());

        // the composed stock module carries the package right after the marker, as the stock entry would
        Map<String, String> modules = modules(request);
        assertEquals(List.of(ClientStylesheetService.COMPOSED_STOCK_MODULE, "site-0.xsl", "pkg-0.xsl"), names(request));
        assertEquals(List.of("hooks.xsl", "client/hooks.xsl", "pkg-0.xsl", "common.xsl"), hrefs(parse(modules.get(ClientStylesheetService.COMPOSED_STOCK_MODULE))));
    }

    @Test
    public void testDeploymentEntryExpandsItsEntities() throws Exception
    {
        ClientStylesheetService service = service(resource("xsl/site/client.xsl"));

        String entry = service.compose(List.of(packageURI())).getString("entry");

        // the compiler's parser has no internal subset to expand &lapp; with
        assertFalse(entry.contains("&lapp;"));
        assertTrue(entry.contains("https://w3id.org/atomgraph/linkeddatahub/apps#Application"));
        assertFalse(entry.contains("<!DOCTYPE"));
    }

    @Test
    public void testKeyFollowsTheEntry() throws Exception
    {
        String stock = service(resource("xsl/stock/client.xsl")).getKey(List.of(PACKAGE));
        String site = service(resource("xsl/site/client.xsl")).getKey(List.of(PACKAGE));
        assertNotEquals(stock, site);

        // an edited entry is another stylesheet, a copied one is the same
        Path edited = Files.createTempFile(sefRoot, "client", ".xsl");
        Files.writeString(edited, Files.readString(Path.of(resource("xsl/site/client.xsl").toURI())).replace("grid.xsl", "grid.xsl\"/><!-- edited --><xsl:include href=\"grid.xsl"));
        assertNotEquals(site, service(edited.toUri().toURL()).getKey(List.of(PACKAGE)));
        Path copied = Files.createTempFile(sefRoot, "client", ".xsl");
        Files.copy(Path.of(resource("xsl/site/client.xsl").toURI()), copied, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        assertEquals(site, service(copied.toUri().toURL()).getKey(List.of(PACKAGE)));
    }

    private ClientStylesheetService service(URL entry) throws Exception
    {
        return new ClientStylesheetService(sefRoot, URI.create("http://sef-compiler:8080/compile"), client(),
            entry, resource("xsl/stock/client.xsl"), new ByteArrayInputStream("stock sef".getBytes(StandardCharsets.UTF_8)));
    }

    private URI packageURI()
    {
        return PACKAGE.resolve("pkg.xsl");
    }

    // a package stylesheet is fetched over HTTP: the client answers every request with the fixture
    private Client client() throws Exception
    {
        Response response = mock(Response.class);
        when(response.getStatusInfo()).thenReturn(Response.Status.OK);
        when(response.readEntity(InputStream.class)).thenAnswer(invocation -> resource("xsl/pkg.xsl").openStream());

        Client client = mock(Client.class, RETURNS_DEEP_STUBS);
        when(client.target(any(URI.class)).request(any(MediaType.class)).get()).thenReturn(response);
        return client;
    }

    private URL resource(String path)
    {
        URL url = getClass().getResource(path);
        if (url == null) throw new IllegalStateException("Test resource '" + path + "' not found");
        return url;
    }

    private Document parse(String xml) throws Exception
    {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        return factory.newDocumentBuilder().parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
    }

    private List<String> hrefs(Document doc)
    {
        return ClientStylesheetService.getModules(doc).stream().map(module -> module.getAttribute("href")).collect(Collectors.toList());
    }

    private List<String> names(JsonObject request)
    {
        return request.getJsonArray("imports").getValuesAs(JsonObject.class).stream().map(module -> module.getString("name")).collect(Collectors.toList());
    }

    private Map<String, String> modules(JsonObject request)
    {
        return request.getJsonArray("imports").getValuesAs(JsonObject.class).stream().collect(Collectors.toMap(module -> module.getString("name"), module -> module.getString("content")));
    }

}
