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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.io.StringReader;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * The document type query as <code>web.xml</code> configures it, run against an in-memory dataset.
 * The types it returns are what <code>acl:accessToClass</code> authorizations are matched against, so which graphs
 * it reads them from decides which writes can change a document's authorizations.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentTypeQueryTest
{

    private static final String NFO = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#";
    private static final String DH = "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#";
    private static final String CLASS = "https://localhost/ns#Class";

    private static final String DOC = "https://localhost/doc/";
    private static final String OTHER = "https://localhost/other/";
    private static final String UPLOAD = "https://localhost/uploads/0123456789abcdef";

    private static String queryString;
    private static Dataset dataset;

    @BeforeAll
    public static void load() throws Exception
    {
        org.w3c.dom.Document webXml = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(Path.of("src/main/webapp/WEB-INF/web.xml").toFile());
        NodeList params = webXml.getElementsByTagName("context-param");
        for (int i = 0; i < params.getLength(); i++)
        {
            Element param = (Element)params.item(i);
            if (param.getElementsByTagName("param-name").item(0).getTextContent().trim().equals(LDHC.documentTypeQuery.getURI()))
                queryString = param.getElementsByTagName("param-value").item(0).getTextContent();
        }

        // the other document's graph claims types for this document and for an upload, which has no graph of its own
        String trig = String.format("""
            <%1$s> { <%1$s> a <%4$sItem> . }
            <%2$s> { <%2$s> a <%4$sItem> .
                     <%1$s> a <%5$sFileDataObject>, <%6$s> .
                     <%3$s> a <%5$sFileDataObject>, <%6$s> . }
            """, DOC, OTHER, UPLOAD, DH, NFO, CLASS);
        dataset = DatasetFactory.create();
        RDFParser.create().source(new StringReader(trig)).lang(Lang.TRIG).parse(dataset);
    }

    private static Set<String> types(String uri)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryString);
        pss.setIri(SPIN.THIS_VAR_NAME, uri);

        Set<String> types = new HashSet<>();
        try (QueryExecution qex = QueryExecution.create(pss.asQuery(), dataset))
        {
            ResultSet results = qex.execSelect();
            results.forEachRemaining(qs -> types.add(qs.getResource("Type").getURI()));
        }
        return types;
    }

    @Test
    public void documentTypesComeFromItsOwnGraph()
    {
        assertEquals(Set.of(DH + "Item"), types(DOC), "another graph cannot add types to a document");
    }

    @Test
    public void uploadIsTypedAFileAndNothingElse()
    {
        assertEquals(Set.of(NFO + "FileDataObject"), types(UPLOAD), "a node without a graph takes no class but nfo:FileDataObject from another graph");
    }

    @Test
    public void unknownNodeHasNoTypes()
    {
        assertEquals(Set.of(), types("https://localhost/missing/"));
    }

}
