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
package com.atomgraph.linkeddatahub.server.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import jakarta.servlet.ServletContext;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import org.w3c.dom.DOMException;
import org.xml.sax.SAXException;

/**
 * Updates master XSLT stylesheets with package import chains.
 * Writes master stylesheets to the webapp's <samp>/static/</samp> directory.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class XSLTMasterUpdater
{
    private static final Logger log = LoggerFactory.getLogger(XSLTMasterUpdater.class);

    private static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";

    private final ServletContext servletContext;

    /**
     * Constructs updater with servlet context.
     *
     * @param servletContext the servlet context
     */
    public XSLTMasterUpdater(ServletContext servletContext)
    {
        this.servletContext = servletContext;
    }

    /**
     * Adds a package import to the master stylesheet, preserving all existing content.
     * Inserts a new <code>xsl:import</code> after the last existing import element.
     *
     * @param packagePath the package path (e.g., "com/linkeddatahub/packages/skos")
     * @throws IOException if file operations fail
     */
    public void addPackageImport(String packagePath) throws IOException
    {
        addPackageImport(getStaticPath().resolve("xsl").resolve("layout.xsl"), packagePath);
    }

    /**
     * Adds a package import to the specified master stylesheet, preserving all existing content.
     *
     * @param masterFile path to the master stylesheet
     * @param packagePath the package path (e.g., "com/linkeddatahub/packages/skos")
     * @throws IOException if file operations fail
     */
    public void addPackageImport(Path masterFile, String packagePath) throws IOException
    {
        try
        {
            Document doc = parseDocument(masterFile);
            Element stylesheet = doc.getDocumentElement();
            String href = "../" + packagePath + "/layout.xsl";

            // Find the last xsl:import child element as insertion anchor, checking for duplicates
            Node lastImport = null;
            NodeList children = stylesheet.getChildNodes();
            for (int i = 0; i < children.getLength(); i++)
            {
                Node child = children.item(i);
                if (child.getNodeType() == Node.ELEMENT_NODE
                        && XSL_NS.equals(child.getNamespaceURI())
                        && "import".equals(child.getLocalName()))
                {
                    if (href.equals(((Element) child).getAttribute("href")))
                    {
                        if (log.isWarnEnabled()) log.warn("xsl:import href=\"{}\" already present in master stylesheet, skipping", href);
                        return;
                    }
                    lastImport = child;
                }
            }

            Element newImport = doc.createElementNS(XSL_NS, "xsl:import");
            newImport.setAttribute("href", href);

            if (lastImport != null)
            {
                // Capture anchor before any insertion — getNextSibling() shifts after insertBefore
                Node anchor = lastImport.getNextSibling();
                stylesheet.insertBefore(newImport, anchor);
                stylesheet.insertBefore(doc.createTextNode("\n    "), newImport);
            }
            else
            {
                // No existing imports — prepend at start of stylesheet
                Node firstChild = stylesheet.getFirstChild();
                stylesheet.insertBefore(newImport, firstChild);
                stylesheet.insertBefore(doc.createTextNode("\n    "), newImport);
            }

            serializeDocument(doc, masterFile);

            if (log.isDebugEnabled()) log.debug("Added xsl:import href=\"{}\" to master stylesheet: {}", href, masterFile);
        }
        catch (ParserConfigurationException | SAXException | TransformerException | DOMException e)
        {
            throw new IOException("Failed to add package import to master stylesheet", e);
        }
    }

    /**
     * Removes a package import from the master stylesheet, preserving all other content.
     *
     * @param packagePath the package path (e.g., "com/linkeddatahub/packages/skos")
     * @throws IOException if file operations fail
     */
    public void removePackageImport(String packagePath) throws IOException
    {
        removePackageImport(getStaticPath().resolve("xsl").resolve("layout.xsl"), packagePath);
    }

    /**
     * Removes a package import from the specified master stylesheet, preserving all other content.
     *
     * @param masterFile path to the master stylesheet
     * @param packagePath the package path (e.g., "com/linkeddatahub/packages/skos")
     * @throws IOException if file operations fail
     */
    public void removePackageImport(Path masterFile, String packagePath) throws IOException
    {
        try
        {
            Document doc = parseDocument(masterFile);
            Element stylesheet = doc.getDocumentElement();
            String href = "../" + packagePath + "/layout.xsl";

            // Find and remove the matching xsl:import element
            Node targetImport = null;
            NodeList children = stylesheet.getChildNodes();
            for (int i = 0; i < children.getLength(); i++)
            {
                Node child = children.item(i);
                if (child.getNodeType() == Node.ELEMENT_NODE
                        && XSL_NS.equals(child.getNamespaceURI())
                        && "import".equals(child.getLocalName())
                        && href.equals(((Element) child).getAttribute("href")))
                {
                    targetImport = child;
                    break;
                }
            }

            if (targetImport == null)
            {
                if (log.isWarnEnabled()) log.warn("xsl:import href=\"{}\" not found in master stylesheet: {}", href, masterFile);
                return;
            }

            // Also remove the preceding text node (whitespace/newline) if present
            Node prev = targetImport.getPreviousSibling();
            if (prev != null && prev.getNodeType() == Node.TEXT_NODE)
                stylesheet.removeChild(prev);

            stylesheet.removeChild(targetImport);

            serializeDocument(doc, masterFile);

            if (log.isDebugEnabled()) log.debug("Removed xsl:import href=\"{}\" from master stylesheet: {}", href, masterFile);
        }
        catch (ParserConfigurationException | SAXException | TransformerException | DOMException e)
        {
            throw new IOException("Failed to remove package import from master stylesheet", e);
        }
    }

    private Document parseDocument(Path file) throws ParserConfigurationException, SAXException, IOException
    {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        DocumentBuilder builder = factory.newDocumentBuilder();
        return builder.parse(file.toFile());
    }

    private void serializeDocument(Document doc, Path file) throws TransformerException
    {
        TransformerFactory transformerFactory = TransformerFactory.newInstance();
        Transformer transformer = transformerFactory.newTransformer();
        transformer.setOutputProperty(OutputKeys.INDENT, "no");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");

        DOMSource source = new DOMSource(doc);
        StreamResult result = new StreamResult(file.toFile());
        transformer.transform(source, result);
    }

    /**
     * Gets the path to the webapp's /static/ directory.
     *
     * @return path to static directory
     */
    private Path getStaticPath()
    {
        String realPath = getServletContext().getRealPath("/static");
        if (realPath == null)
            throw new IllegalStateException("Could not resolve real path for /static directory");
        return Paths.get(realPath);
    }

    /**
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

}
