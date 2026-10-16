/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.command.imports;

import java.io.PrintWriter;
import java.io.StringReader;
import java.io.StringWriter;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

/**
 * Tests how an ended import's outcome is reported, in the shape the platform writes it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportWaitTest
{

    private static final String IMPORT = "https://localhost:4443/authors/#id837da0c2";

    private static Model model(String ntriples)
    {
        Model model = ModelFactory.createDefaultModel();
        RDFParser.create().source(new StringReader(ntriples)).lang(Lang.NTRIPLES).parse(model);
        return model;
    }

    @Test
    public void successReportsTripleCount()
    {
        Model model = model("""
            <https://localhost:4443/authors/#id837da0c2> <http://www.w3.org/ns/prov#endedAtTime> "2026-10-16T10:50:47.666Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
            <https://localhost:4443/authors/#id979b9d88> <http://www.w3.org/ns/prov#wasGeneratedBy> <https://localhost:4443/authors/#id837da0c2> .
            <https://localhost:4443/authors/#id979b9d88> <http://rdfs.org/ns/void#triples> "16"^^<http://www.w3.org/2001/XMLSchema#long> .
            <https://localhost:4443/authors/#id979b9d88> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://rdfs.org/ns/void#Dataset> .
            """);
        StringWriter err = new StringWriter();

        assertEquals(0, ImportWait.outcome(model, model.createResource(IMPORT), new PrintWriter(err, true)));
        assertTrue(err.toString().contains("16 triples"), err.toString());
    }

    @Test
    public void failureReportsMessageAndExitsOne()
    {
        Model model = model("""
            <https://localhost:4443/authors/#id837da0c2> <http://www.w3.org/ns/prov#endedAtTime> "2026-10-16T10:50:47.666Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
            <https://localhost:4443/authors/#err> <http://www.w3.org/ns/prov#wasGeneratedBy> <https://localhost:4443/authors/#id837da0c2> .
            <https://localhost:4443/authors/#err> <http://purl.org/dc/terms/description> "Missing dct:title" .
            """);
        StringWriter err = new StringWriter();

        assertEquals(1, ImportWait.outcome(model, model.createResource(IMPORT), new PrintWriter(err, true)));
        assertTrue(err.toString().contains("Missing dct:title"), err.toString());
    }

}
