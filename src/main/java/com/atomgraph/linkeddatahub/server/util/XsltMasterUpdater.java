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
import jakarta.ws.rs.InternalServerErrorException;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import org.w3c.dom.DOMException;
import org.xml.sax.SAXException;

/**
 * Updates master XSLT stylesheets with package import chains.
 * Writes master stylesheets to the webapp's /static/ directory.
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
     * Regenerates the master stylesheet for the application.
     * The master stylesheet must exist at /static/xsl/layout.xsl.
     * This method loads it and adds/updates xsl:import elements for packages.
     *
     * @param packagePaths list of package paths to import (e.g., ["com/linkeddatahub/packages/skos"])
     * @throws IOException if file operations fail
     */
    public void regenerateMasterStylesheet(List<String> packagePaths) throws IOException
    {
        try
        {
            Path staticDir = getStaticPath();
            Path xslDir = staticDir.resolve("xsl");
            Path masterFile = xslDir.resolve("layout.xsl");

            // Master stylesheet must exist
            if (!Files.exists(masterFile))
            {
                throw new InternalServerErrorException("Master stylesheet does not exist: " + masterFile);
            }

            // Load existing master stylesheet
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            DocumentBuilder builder = factory.newDocumentBuilder();

            if (log.isDebugEnabled()) log.debug("Loading master stylesheet: {}", masterFile);
            Document doc = builder.parse(masterFile.toFile());

            // Get stylesheet root element
            Element stylesheet = doc.getDocumentElement();
            if (!stylesheet.getLocalName().equals("stylesheet") || !XSL_NS.equals(stylesheet.getNamespaceURI()))
            {
                throw new IllegalStateException("Root element must be xsl:stylesheet");
            }

            // Remove all existing xsl:import elements for packages
            removePackageImports(stylesheet);

            // Add xsl:import elements for packages (after system import, before everything else)
            Element systemImport = findSystemImport(stylesheet);
            Node insertAfter = systemImport;

            if (packagePaths != null && !packagePaths.isEmpty())
            {
                for (String packagePath : packagePaths)
                {
                    Element importElement = doc.createElementNS(XSL_NS, "xsl:import");
                    importElement.setAttribute("href", "../" + packagePath + "/layout.xsl");

                    // Add comment
                    org.w3c.dom.Comment comment = doc.createComment(" Package: " + packagePath + " ");
                    if (insertAfter.getNextSibling() != null)
                    {
                        stylesheet.insertBefore(comment, insertAfter.getNextSibling());
                        stylesheet.insertBefore(importElement, insertAfter.getNextSibling());
                    }
                    else
                    {
                        stylesheet.appendChild(comment);
                        stylesheet.appendChild(importElement);
                    }
                    insertAfter = importElement;

                    if (log.isDebugEnabled()) log.debug("Added xsl:import for package: {}", packagePath);
                }
            }

            // Write to file
            Files.createDirectories(xslDir);
            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            Transformer transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
            transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");

            DOMSource source = new DOMSource(doc);
            StreamResult result = new StreamResult(masterFile.toFile());
            transformer.transform(source, result);

            if (log.isDebugEnabled()) log.debug("Regenerated master stylesheet at: {}", masterFile);
        }
        catch (InternalServerErrorException | IOException | IllegalArgumentException | IllegalStateException | ParserConfigurationException | TransformerException | DOMException | SAXException e)
        {
            throw new IOException("Failed to regenerate master stylesheet", e);
        }
    }

    /**
     * Finds the system stylesheet import element.
     */
    private Element findSystemImport(Element stylesheet)
    {
        NodeList imports = stylesheet.getElementsByTagNameNS(XSL_NS, "import");
        for (int i = 0; i < imports.getLength(); i++)
        {
            Element importElem = (Element) imports.item(i);
            String href = importElem.getAttribute("href");
            if (href.contains("/com/atomgraph/linkeddatahub/xsl/bootstrap/"))
            {
                return importElem;
            }
        }
        throw new IllegalStateException("System stylesheet import not found");
    }

    /**
     * Removes all <samp>xsl:import</samp> elements for packages.
     * Identifies package imports by their href pattern: relative paths that are not the system stylesheet.
     */
    private void removePackageImports(Element stylesheet)
    {
        NodeList imports = stylesheet.getElementsByTagNameNS(XSL_NS, "import");
        List<Element> toRemove = new ArrayList<>();

        for (int i = 0; i < imports.getLength(); i++)
        {
            Element importElem = (Element) imports.item(i);
            String href = importElem.getAttribute("href");

            // Check if this is a package import based on href pattern
            // Package imports: start with "../", don't contain system path, end with "/layout.xsl"
            if (href.startsWith("../") &&
                !href.contains("/com/atomgraph/linkeddatahub/xsl/") &&
                href.endsWith("/layout.xsl"))
            {
                toRemove.add(importElem);
            }
        }

        for (Element elem : toRemove)
        {
            // Remove preceding comment if it exists
            Node prev = elem.getPreviousSibling();
            while (prev != null && prev.getNodeType() == Node.TEXT_NODE)
            {
                prev = prev.getPreviousSibling();
            }
            if (prev != null && prev.getNodeType() == Node.COMMENT_NODE)
            {
                stylesheet.removeChild(prev);
            }

            stylesheet.removeChild(elem);
        }
    }

    /**
     * Gets the path to the webapp's /static/ directory.
     *
     * @return path to static directory
     */
    private Path getStaticPath()
    {
        String realPath = servletContext.getRealPath("/static");
        if (realPath == null)
            throw new IllegalStateException("Could not resolve real path for /static directory");
        return Paths.get(realPath);
    }

}
