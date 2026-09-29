/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.util;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;
import javax.xml.parsers.DocumentBuilderFactory;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Where package imports land decides what a package can override, so these pin the insertion point.
 */
public class StylesheetComposerTest
{

    private static final String XSL_NS = StylesheetComposer.XSL_NS;

    @Test
    public void testMarkerIsLastHooksImport() throws Exception
    {
        Document doc = parse(
            "<xsl:import href=\"../../../../com/atomgraph/client/xsl/common.xsl\"/>" +
            "<xsl:import href=\"hooks.xsl\"/>" +
            "<xsl:import href=\"client/hooks.xsl\"/>" +
            "<xsl:import href=\"common.xsl\"/>");

        assertEquals("client/hooks.xsl", StylesheetComposer.getMarker(doc).getAttribute("href"));
    }

    @Test
    public void testNoMarker() throws Exception
    {
        assertNull(StylesheetComposer.getMarker(parse("<xsl:import href=\"common.xsl\"/>")));
        assertFalse(StylesheetComposer.hasMarker(parse("")));
    }

    @Test
    public void testInsertAtMarkerKeepsOrder() throws Exception
    {
        Document doc = parse(
            "<xsl:import href=\"hooks.xsl\"/>" +
            "<xsl:import href=\"common.xsl\"/>" +
            "<xsl:include href=\"client/block.xsl\"/>");

        assertTrue(StylesheetComposer.insertImports(doc, List.of("pkg-0.xsl", "pkg-1.xsl")));

        assertEquals(List.of("hooks.xsl", "pkg-0.xsl", "pkg-1.xsl", "common.xsl"), hrefs(doc));
    }

    @Test
    public void testInsertWithoutMarkerGoesAfterLastImport() throws Exception
    {
        Document doc = parse(
            "<xsl:import href=\"a.xsl\"/>" +
            "<xsl:import href=\"b.xsl\"/>" +
            "<xsl:template match=\"/\"/>");

        assertFalse(StylesheetComposer.insertImports(doc, List.of("pkg-0.xsl")));

        assertEquals(List.of("a.xsl", "b.xsl", "pkg-0.xsl"), hrefs(doc));
    }

    @Test
    public void testInsertWithoutImportsGoesFirst() throws Exception
    {
        Document doc = parse("<xsl:template match=\"/\"/>");

        assertFalse(StylesheetComposer.insertImports(doc, List.of("pkg-0.xsl")));

        Element first = (Element)doc.getDocumentElement().getFirstChild();
        assertEquals("import", first.getLocalName());
        assertEquals("pkg-0.xsl", first.getAttribute("href"));
    }

    private Document parse(String declarations) throws Exception
    {
        String xml = "<xsl:stylesheet version=\"3.0\" xmlns:xsl=\"" + XSL_NS + "\">" + declarations + "</xsl:stylesheet>";
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        return factory.newDocumentBuilder().parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
    }

    private List<String> hrefs(Document doc)
    {
        return StylesheetComposer.getImports(doc).stream().map(imp -> imp.getAttribute("href")).collect(Collectors.toList());
    }

}
