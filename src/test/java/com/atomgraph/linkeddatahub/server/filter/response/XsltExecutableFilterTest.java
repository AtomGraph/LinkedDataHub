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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.impl.PackageImpl;
import com.atomgraph.linkeddatahub.server.util.SecureXML;
import jakarta.servlet.ServletContext;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

/**
 * Tests the composition of the application stylesheet with package stylesheet imports.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class XsltExecutableFilterTest
{

    private static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";
    private static final URI STYLESHEET_URI = URI.create("file:/usr/local/tomcat/webapps/ROOT/static/xsl/layout.xsl");
    private static final URI A_XSL_URI = URI.create("https://packages.example.org/a/layout.xsl");
    private static final URI B_XSL_URI = URI.create("https://packages.example.org/b/layout.xsl");

    @Mock private ServletContext servletContext;
    @Mock private com.atomgraph.linkeddatahub.apps.model.Application application;

    private XsltExecutableFilter filter;
    private Model model;

    @BeforeEach
    public void setUp()
    {
        filter = new XsltExecutableFilter();
        filter.servletContext = servletContext;
        model = ModelFactory.createDefaultModel();
    }

    @Test
    public void testGetPackagesOrderedByURI()
    {
        Resource pkgB = model.createResource("https://packages.example.org/b#this");
        Resource pkgA = model.createResource("https://packages.example.org/a#this");
        when(application.getImportedPackages()).thenReturn(new HashSet<>(List.of(pkgB, pkgA)));

        assertEquals(List.of(URI.create(pkgA.getURI()), URI.create(pkgB.getURI())), filter.getPackages(application));
    }

    @Test
    public void testGetStylesheetsSkipsUnresolvedAndOntologyOnlyPackages()
    {
        URI pkgA = URI.create("https://packages.example.org/a#this");
        URI pkgB = URI.create("https://packages.example.org/b#this");
        URI pkgC = URI.create("https://packages.example.org/c#this");
        model.createResource(pkgA.toString()).addProperty(AC.stylesheet, model.createResource(A_XSL_URI.toString()));
        model.createResource(pkgC.toString()); // ontology-only: no ac:stylesheet

        XsltExecutableFilter spied = spy(filter);
        doReturn(asPackage(pkgA)).when(spied).getPackage(pkgA.toString());
        doReturn(null).when(spied).getPackage(pkgB.toString()); // description could not be resolved
        doReturn(asPackage(pkgC)).when(spied).getPackage(pkgC.toString());

        assertEquals(List.of(A_XSL_URI), spied.getStylesheets(List.of(pkgA, pkgB, pkgC)));
    }

    private com.atomgraph.linkeddatahub.apps.model.Package asPackage(URI uri)
    {
        return new PackageImpl(model.createResource(uri.toString()).asNode(), (EnhGraph)model);
    }

    @Test
    public void testAppendImportsAfterExistingImport() throws Exception
    {
        Document doc = parse("<xsl:stylesheet version=\"3.0\" xmlns:xsl=\"" + XSL_NS + "\">" +
            "<xsl:import href=\"../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl\"/>" +
            "<xsl:template match=\"/\"/>" +
            "</xsl:stylesheet>");

        filter.appendImports(doc, List.of(A_XSL_URI, B_XSL_URI));

        List<Element> children = childElements(doc);
        assertEquals(4, children.size());
        assertEquals("../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl", children.get(0).getAttribute("href"));
        assertEquals(A_XSL_URI.toString(), children.get(1).getAttribute("href"));
        assertEquals(B_XSL_URI.toString(), children.get(2).getAttribute("href"));
        assertEquals("template", children.get(3).getLocalName());
    }

    @Test
    public void testAppendImportsWithoutExistingImports() throws Exception
    {
        Document doc = parse("<xsl:stylesheet version=\"3.0\" xmlns:xsl=\"" + XSL_NS + "\">" +
            "<xsl:template match=\"/\"/>" +
            "</xsl:stylesheet>");

        filter.appendImports(doc, List.of(A_XSL_URI));

        List<Element> children = childElements(doc);
        assertEquals(2, children.size());
        assertEquals("import", children.get(0).getLocalName());
        assertEquals(A_XSL_URI.toString(), children.get(0).getAttribute("href"));
        assertEquals("template", children.get(1).getLocalName());
    }

    @Test
    public void testCacheKeyWithoutImportsIsStylesheetURI()
    {
        assertEquals(STYLESHEET_URI, filter.getCacheKey(STYLESHEET_URI, List.of()));
    }

    @Test
    public void testCacheKeyIsImportOrderInvariant()
    {
        assertEquals(filter.getCacheKey(STYLESHEET_URI, List.of(A_XSL_URI, B_XSL_URI)),
            filter.getCacheKey(STYLESHEET_URI, List.of(B_XSL_URI, A_XSL_URI)));
    }

    @Test
    public void testCacheKeyDependsOnImportSet()
    {
        assertNotEquals(filter.getCacheKey(STYLESHEET_URI, List.of(A_XSL_URI, B_XSL_URI)),
            filter.getCacheKey(STYLESHEET_URI, List.of(A_XSL_URI)));
        assertNotEquals(STYLESHEET_URI, filter.getCacheKey(STYLESHEET_URI, List.of(A_XSL_URI)));
    }

    @Test
    public void testPublicURIOfWebappStylesheet() throws Exception
    {
        when(servletContext.getResource("/")).thenReturn(new URL("file:/usr/local/tomcat/webapps/ROOT/"));
        when(application.getBaseURI()).thenReturn(URI.create("https://localhost:4443/"));

        assertEquals(URI.create("https://localhost:4443/static/xsl/layout.xsl"), filter.getPublicURI(application, STYLESHEET_URI));
    }

    @Test
    public void testPublicURIPassesThroughHTTPS() throws Exception
    {
        assertEquals(A_XSL_URI, filter.getPublicURI(application, A_XSL_URI));
    }

    @Test
    public void testPublicURIPassesThroughOutsideWebappRoot() throws Exception
    {
        when(servletContext.getResource("/")).thenReturn(new URL("file:/usr/local/tomcat/webapps/ROOT/"));
        URI outside = URI.create("file:/etc/xsl/layout.xsl");

        assertEquals(outside, filter.getPublicURI(application, outside));
    }

    private Document parse(String xml) throws Exception
    {
        return SecureXML.newDocumentBuilderFactory().newDocumentBuilder().
            parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
    }

    private List<Element> childElements(Document doc)
    {
        List<Element> elements = new ArrayList<>();
        NodeList children = doc.getDocumentElement().getChildNodes();
        for (int i = 0; i < children.getLength(); i++)
            if (children.item(i).getNodeType() == Node.ELEMENT_NODE) elements.add((Element)children.item(i));

        return elements;
    }

}
