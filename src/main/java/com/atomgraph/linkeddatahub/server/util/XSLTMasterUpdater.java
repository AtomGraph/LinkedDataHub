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
import jakarta.servlet.ServletContext;
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
import java.util.List;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import org.w3c.dom.DOMException;

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
    private static final String SYSTEM_STYLESHEET_HREF = "../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl";

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
     * Creates a fresh stylesheet with system import followed by package imports.
     *
     * @param packagePaths list of package paths to import (e.g., ["com/linkeddatahub/packages/skos"])
     * @throws IOException if file operations fail
     */
    public void regenerateMasterStylesheet(List<String> packagePaths) throws IOException
    {
        regenerateMasterStylesheet(getStaticPath().resolve("xsl").resolve("layout.xsl"), packagePaths); // TO-DO: move to configuration
    }
    
    public void regenerateMasterStylesheet(Path masterFile, List<String> packagePaths) throws IOException
    {
        try
        {
            // Create fresh XML document
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.newDocument();

            // Create stylesheet root element
            Element stylesheet = doc.createElementNS(XSL_NS, "xsl:stylesheet");
            stylesheet.setAttribute("version", "3.0");
            stylesheet.setAttribute("xmlns:xsl", XSL_NS);
            stylesheet.setAttribute("xmlns:xs", "http://www.w3.org/2001/XMLSchema");
            stylesheet.setAttribute("exclude-result-prefixes", "xs");
            doc.appendChild(stylesheet);

            // Add system stylesheet import (lowest priority)
            stylesheet.appendChild(doc.createTextNode("\n\n    "));
            stylesheet.appendChild(doc.createComment("System stylesheet (lowest priority) "));
            stylesheet.appendChild(doc.createTextNode("\n    "));
            Element systemImport = doc.createElementNS(XSL_NS, "xsl:import");
            systemImport.setAttribute("href", SYSTEM_STYLESHEET_HREF);
            stylesheet.appendChild(systemImport);

            // Add package stylesheet imports
            if (packagePaths != null && !packagePaths.isEmpty())
            {
                stylesheet.appendChild(doc.createTextNode("\n\n    "));
                stylesheet.appendChild(doc.createComment(" Package stylesheets "));

                for (String packagePath : packagePaths)
                {
                    stylesheet.appendChild(doc.createTextNode("\n    "));
                    Element importElement = doc.createElementNS(XSL_NS, "xsl:import");
                    importElement.setAttribute("href", "../" + packagePath + "/layout.xsl");
                    stylesheet.appendChild(importElement);

                    if (log.isDebugEnabled()) log.debug("Added xsl:import for package: {}", packagePath);
                }
            }

            stylesheet.appendChild(doc.createTextNode("\n\n"));

            // Write to file
            Files.createDirectories(masterFile.getParent());
            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            Transformer transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
            transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
            transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");

            DOMSource source = new DOMSource(doc);
            StreamResult result = new StreamResult(masterFile.toFile());
            transformer.transform(source, result);

            if (log.isDebugEnabled()) log.debug("Regenerated master stylesheet at: {}", masterFile);
        }
        catch (ParserConfigurationException | TransformerException | DOMException e)
        {
            throw new IOException("Failed to regenerate master stylesheet", e);
        }
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
