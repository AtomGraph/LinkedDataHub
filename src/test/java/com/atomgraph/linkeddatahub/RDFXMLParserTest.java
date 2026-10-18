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
package com.atomgraph.linkeddatahub;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFFormat;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.riot.RDFWriter;
import org.apache.jena.datatypes.xsd.impl.XMLLiteralType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The platform reads RDF/XML with a parser that takes an {@code rdf:RDF} inside an XML literal as the literal's content,
 * which Jena's default does not (apache/jena#4334).
 */
public class RDFXMLParserTest
{

    private static final String RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

    @BeforeAll
    public static void register()
    {
        Application.registerRDFXMLParser();
    }

    private static Model parse(String rdfXml)
    {
        Model model = ModelFactory.createDefaultModel();
        RDFParser.fromString(rdfXml, Lang.RDFXML).parse(model);
        return model;
    }

    /** The default threw "Inconsistent parserMode:TOP" at the end tag after the literal */
    @Test
    public void testRDFInsideLiteral()
    {
        Model model = parse("<rdf:RDF xmlns:rdf=\"" + RDF + "\" xmlns:ex=\"http://example.org/\">" +
            "<rdf:Description rdf:about=\"http://example.org/s\">" +
            "<ex:p rdf:parseType=\"Literal\"><x xmlns=\"http://example.org/x\"><rdf:RDF><rdf:Description rdf:about=\"http://example.org/inner\"/></rdf:RDF></x></ex:p>" +
            "<ex:q>after</ex:q>" +
            "</rdf:Description>" +
            "</rdf:RDF>");

        assertEquals(2, model.size());
    }

    /** The default returned an empty graph and no error */
    @Test
    public void testNestedRDFInsideLiteral()
    {
        Model model = parse("<rdf:RDF xmlns:rdf=\"" + RDF + "\" xmlns:ex=\"http://example.org/\">" +
            "<rdf:Description rdf:about=\"http://example.org/s\">" +
            "<ex:p rdf:parseType=\"Literal\"><rdf:RDF><rdf:RDF/></rdf:RDF></ex:p>" +
            "</rdf:Description>" +
            "<rdf:Description rdf:about=\"http://example.org/t\">" +
            "<ex:q>after</ex:q>" +
            "</rdf:Description>" +
            "</rdf:RDF>");

        assertEquals(2, model.size());
    }

    /** What the platform's RDF/XML writer writes, the platform's RDF/XML parser reads back. The literal is in canonical
     * form, as a stored XML literal is: a self-closing element would come back with an end tag */
    @Test
    public void testRoundTrip()
    {
        Model model = ModelFactory.createDefaultModel();
        model.add(model.createResource("http://example.org/s"), model.createProperty("http://example.org/p"),
            model.createTypedLiteral("<x xmlns=\"http://example.org/x\"><rdf:RDF xmlns:rdf=\"" + RDF + "\"><rdf:Description rdf:about=\"http://example.org/inner\"></rdf:Description></rdf:RDF></x>", XMLLiteralType.rdfXMLLiteral));
        model.add(model.createResource("http://example.org/s"), model.createProperty("http://example.org/q"), "after");

        String rdfXml = RDFWriter.source(model).format(RDFFormat.RDFXML_PLAIN).asString();
        assertTrue(rdfXml.contains("rdf:parseType=\"Literal\""), "the literal is written as markup");
        assertTrue(parse(rdfXml).isIsomorphicWith(model));
    }

}
