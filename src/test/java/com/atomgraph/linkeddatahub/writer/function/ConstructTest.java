/*
 * Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>.
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
package com.atomgraph.linkeddatahub.writer.function;

import java.io.StringWriter;
import java.net.URI;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmMap;
import net.sf.saxon.s9api.XdmValue;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for the {@link Construct} Saxon extension function.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ConstructTest
{

    public static final String CLASS_URI = "http://test/ontology#MyClass";
    public static final String PROP_URI = "http://test/ontology#prop";
    public static final String VALUE_URI = "http://test/value";

    public static final String CONSTRUCT_QUERY =
        "CONSTRUCT { ?this <" + PROP_URI + "> <" + VALUE_URI + "> } WHERE {}";

    private Processor processor;
    private Construct construct;

    @BeforeEach
    public void setUp()
    {
        processor = new Processor(false);
        construct = new Construct(processor);
    }

    private XdmMap buildMap(String classUri, String... queries) throws Exception
    {
        XdmMap map = new XdmMap();
        XdmAtomicValue key = new XdmAtomicValue(new URI(classUri));
        XdmValue value = new XdmValue(java.util.Arrays.stream(queries)
            .map(XdmAtomicValue::new)
            .collect(java.util.stream.Collectors.toList()));
        return map.put(key, value);
    }

    private Model parseResult(XdmValue result) throws Exception
    {
        StringWriter sw = new StringWriter();
        Serializer ser = processor.newSerializer(sw);
        ser.serializeXdmValue(result);
        Model model = ModelFactory.createDefaultModel();
        model.read(new java.io.StringReader(sw.toString()), null, "RDF/XML");
        return model;
    }

    @Test
    public void testConstruct() throws Exception
    {
        XdmValue result = construct.call(new XdmValue[] { buildMap(CLASS_URI, CONSTRUCT_QUERY) });
        Model model = parseResult(result);

        assertTrue(model.contains(null, RDF.type, model.createResource(CLASS_URI)));
        assertTrue(model.contains(null, model.createProperty(PROP_URI), model.createResource(VALUE_URI)));
    }

    @Test
    public void testMultipleConstructors() throws Exception
    {
        String prop2 = "http://test/ontology#prop2";
        String value2 = "http://test/value2";
        String query2 = "CONSTRUCT { ?this <" + prop2 + "> <" + value2 + "> } WHERE {}";

        XdmValue result = construct.call(new XdmValue[] { buildMap(CLASS_URI, CONSTRUCT_QUERY, query2) });
        Model model = parseResult(result);

        assertTrue(model.contains(null, model.createProperty(PROP_URI), model.createResource(VALUE_URI)));
        assertTrue(model.contains(null, model.createProperty(prop2), model.createResource(value2)));
    }

    @Test
    public void testEmptyMap() throws Exception
    {
        XdmValue result = construct.call(new XdmValue[] { new XdmMap() });
        Model model = parseResult(result);

        assertTrue(model.isEmpty());
    }

    @Test
    public void testInvalidSparql() throws Exception
    {
        assertThrows(QueryParseException.class, () -> construct.call(new XdmValue[] { buildMap(CLASS_URI, "NOT VALID SPARQL") }));
    }

}
