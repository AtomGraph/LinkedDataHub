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

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParserFactory;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;

/**
 * Factory helpers for XML parsers hardened against XXE and entity-expansion (billion laughs) attacks.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html">OWASP XXE Prevention</a>
 */
public final class SecureXML
{

    private SecureXML()
    {
    }

    /**
     * Returns a namespace-aware {@link DocumentBuilderFactory} with DTDs and external entities disabled.
     * Suitable for parsing trusted internal XML (e.g. stylesheets) that never carries a DOCTYPE.
     *
     * @return hardened document builder factory
     * @throws ParserConfigurationException if a feature cannot be set
     */
    public static DocumentBuilderFactory newDocumentBuilderFactory() throws ParserConfigurationException
    {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setXIncludeAware(false);
        factory.setExpandEntityReferences(false);
        return factory;
    }

    /**
     * Returns an {@link XMLReader} hardened for parsing untrusted external content.
     * Secure processing caps entity expansion (billion laughs) and external entities are disabled,
     * while a benign internal DOCTYPE (e.g. XHTML) is still tolerated.
     *
     * @return hardened XML reader
     * @throws ParserConfigurationException if a feature cannot be set
     * @throws SAXException if the reader cannot be created
     */
    public static XMLReader newXMLReader() throws ParserConfigurationException, SAXException
    {
        SAXParserFactory factory = SAXParserFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
        return factory.newSAXParser().getXMLReader();
    }

}
