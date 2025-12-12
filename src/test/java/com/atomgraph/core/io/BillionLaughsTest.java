package com.atomgraph.core.io;

import org.apache.jena.rdf.model.*;
import org.apache.jena.riot.*;
import org.apache.jena.riot.system.ErrorHandlerFactory;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import org.apache.jena.riot.system.StreamRDFLib;

public class BillionLaughsTest {

    private static final String MALICIOUS = """
        <?xml version="1.0"?>
        <!DOCTYPE rdf:RDF [
          <!ENTITY lol "lol">
          <!ENTITY lol1 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
          <!ENTITY lol2 "&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;">
          <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
          <!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;">
          <!ENTITY lol5 "&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;">
          <!ENTITY lol6 "&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;">
          <!ENTITY lol7 "&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;">
          <!ENTITY lol8 "&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;">
          <!ENTITY lol9 "&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;">
        ]>
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                 xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
          <rdf:Description rdf:about="http://example.org/malicious">
            <rdfs:label>&lol9;</rdfs:label>
          </rdf:Description>
        </rdf:RDF>
        """;

    @Test(expected = RiotException.class)
    public void testBillionLaughs() {
        Model m = ModelFactory.createDefaultModel();

        ByteArrayInputStream bais = new ByteArrayInputStream(MALICIOUS.getBytes(StandardCharsets.UTF_8));

        RDFParser parser = RDFParser.create()
                .lang(Lang.RDFXML)
                .errorHandler(ErrorHandlerFactory.errorHandlerStrict)
                .checking(true)
                .base("http://example.org/")
                .source(bais)
                .build();

        System.out.println("Starting parse...");
        parser.parse(StreamRDFLib.graph(m.getGraph()));
        System.out.println("Model size: " + m.size());
    }
}
