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

package com.atomgraph.linkeddatahub.cli.util;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Tests for {@link SequenceNumbers}.
 */
public class SequenceNumbersTest
{

    private static final String DOC = "https://localhost:4443/some/";

    @Test
    public void returnsFirstMembershipPropertyOnEmptyModel()
    {
        Model model = ModelFactory.createDefaultModel();

        assertEquals(RDF.li(1), SequenceNumbers.nextSequenceProperty(model, model.createResource(DOC)));
    }

    @Test
    public void returnsMaxPlusOneWithGaps()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource doc = model.createResource(DOC);
        doc.addProperty(RDF.li(1), model.createResource());
        doc.addProperty(RDF.li(2), model.createResource());
        doc.addProperty(RDF.li(7), model.createResource());

        assertEquals(RDF.li(8), SequenceNumbers.nextSequenceProperty(model, doc));
    }

    @Test
    public void ignoresOtherSubjects()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost:4443/other/").addProperty(RDF.li(5), model.createResource());

        assertEquals(RDF.li(1), SequenceNumbers.nextSequenceProperty(model, model.createResource(DOC)));
    }

    @Test
    public void ignoresNonNumericSuffixes()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource doc = model.createResource(DOC);
        doc.addProperty(model.createProperty(RDF.getURI() + "_x"), model.createResource());
        doc.addProperty(RDF.li(3), model.createResource());

        assertEquals(RDF.li(4), SequenceNumbers.nextSequenceProperty(model, doc));
    }

}
