/*
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
 */
package com.atomgraph.linkeddatahub.writer.function;

import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmValue;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the server-side construct subset emitted in the Traqula AST shape.
 */
public class ParseQueryTest
{

    private String parse(String query) throws SaxonApiException
    {
        XdmValue result = new ParseQuery().call(new XdmValue[] { new XdmAtomicValue(query) });
        return result.itemAt(0).getStringValue().replaceAll("\\s+", "");
    }

    @Test
    public void testConstructTemplateUsesTypedTraqulaTerms() throws SaxonApiException
    {
        String json = parse("CONSTRUCT { ?s <https://example.com/p> \"hello\"@en } WHERE { }");

        assertTrue(json.contains("\"subType\":\"construct\""));
        assertTrue(json.contains("\"template\":{\"type\":\"pattern\",\"subType\":\"bgp\""));
        assertTrue(json.contains("\"subType\":\"variable\",\"value\":\"s\""));
        assertTrue(json.contains("\"subType\":\"namedNode\",\"value\":\"https://example.com/p\""));
        assertTrue(json.contains("\"subType\":\"literal\",\"value\":\"hello\",\"langOrIri\":\"en\""), json);
        assertTrue(json.contains("\"where\":{\"type\":\"pattern\",\"subType\":\"group\",\"patterns\":[]"));
    }

    @Test
    public void testNonemptyWhereIsMarkedAsNonInstantiable() throws SaxonApiException
    {
        String json = parse("CONSTRUCT { ?s <https://example.com/p> ?o } WHERE { ?s ?p ?o }");

        assertTrue(json.contains("\"where\":{\"type\":\"pattern\",\"subType\":\"group\",\"patterns\":[{}]"), json);
    }

}
