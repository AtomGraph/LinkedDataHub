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

import java.util.ArrayList;
import java.util.List;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Composes package stylesheets into a platform stylesheet module by inserting <code>xsl:import</code>
 * elements at the <em>marker</em>: the last existing import whose <code>href</code> ends in
 * {@value #MARKER_SUFFIX}.
 *
 * Import precedence beats template priority, so where the package imports land decides what a package
 * can override. The platform's entry stylesheets import Web-Client's layer first, then the open modes
 * (<code>hooks.xsl</code> and, on the client, <code>client/hooks.xsl</code>), then their own sealed
 * modules. Inserted right after the marker, a package outranks the open modes' generic fallbacks and
 * nothing else - it cannot replace the page shell, a typed rule or a global.
 *
 * A stylesheet without a marker (a custom application stylesheet written before the marker existed)
 * keeps the previous behaviour: the imports go after its last import, where they outrank everything the
 * stylesheet imports. Callers log that case; the semantics are theirs to accept.
 *
 * Shared by the server-side composer ({@code XsltExecutableFilter}) and the client-side one
 * ({@code ClientStylesheetService}), so both paths compose the same way.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class StylesheetComposer
{

    /** XSLT namespace */
    public static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";
    /** Suffix of the import href that marks where package imports are inserted */
    public static final String MARKER_SUFFIX = "hooks.xsl";

    private StylesheetComposer() { }

    /**
     * Returns the top-level <code>xsl:import</code> elements of a stylesheet document, in document order.
     *
     * @param doc stylesheet document
     * @return import elements
     */
    public static List<Element> getImports(Document doc)
    {
        List<Element> imports = new ArrayList<>();
        NodeList children = doc.getDocumentElement().getChildNodes();
        for (int i = 0; i < children.getLength(); i++)
        {
            Node child = children.item(i);
            if (child.getNodeType() == Node.ELEMENT_NODE &&
                    XSL_NS.equals(child.getNamespaceURI()) &&
                    "import".equals(child.getLocalName()))
                imports.add((Element)child);
        }
        return imports;
    }

    /**
     * Returns the marker import - the last import whose href ends in {@value #MARKER_SUFFIX} - or
     * <code>null</code> when the stylesheet has none.
     *
     * @param doc stylesheet document
     * @return marker import element or null
     */
    public static Element getMarker(Document doc)
    {
        Element marker = null;
        for (Element imp : getImports(doc))
            if (imp.getAttribute("href").endsWith(MARKER_SUFFIX)) marker = imp;
        return marker;
    }

    /**
     * Returns true if the stylesheet document declares the marker import.
     *
     * @param doc stylesheet document
     * @return true if marked
     */
    public static boolean hasMarker(Document doc)
    {
        return getMarker(doc) != null;
    }

    /**
     * Inserts <code>xsl:import</code> elements for the given hrefs, in order, right after the marker
     * import - or, when there is none, after the last existing import (and first of all when there are
     * no imports).
     *
     * @param doc stylesheet document
     * @param hrefs import hrefs
     * @return true if the imports were inserted at a marker, false if the stylesheet had none
     */
    public static boolean insertImports(Document doc, List<String> hrefs)
    {
        Element stylesheetElem = doc.getDocumentElement();
        Element marker = getMarker(doc);
        List<Element> imports = getImports(doc);
        Node anchor = marker != null ? marker : (imports.isEmpty() ? null : imports.get(imports.size() - 1));

        for (String href : hrefs)
        {
            Element newImport = doc.createElementNS(XSL_NS, "xsl:import");
            newImport.setAttribute("href", href);

            Node before = (anchor != null) ? anchor.getNextSibling() : stylesheetElem.getFirstChild();
            stylesheetElem.insertBefore(newImport, before);
            anchor = newImport;
        }

        return marker != null;
    }

}
