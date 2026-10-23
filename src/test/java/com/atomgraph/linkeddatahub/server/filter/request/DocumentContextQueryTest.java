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

import com.atomgraph.linkeddatahub.server.util.DocumentContext;
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
 * The document context query as <code>web.xml</code> configures it, run against an in-memory dataset.
 * Its rows are what authorizations are matched against, so which graphs it reads them from decides which writes can
 * change a document's authorizations.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentContextQueryTest
{

    private static final String ACL = "http://www.w3.org/ns/auth/acl#";
    private static final String NFO = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#";
    private static final String DH = "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#";
    private static final String DEF = "https://w3id.org/atomgraph/linkeddatahub/default#";
    private static final String SIOC = "http://rdfs.org/sioc/ns#";
    private static final String CLASS = "https://localhost/ns#Class";

    private static final String ROOT = "https://localhost/";
    private static final String CONTAINER = "https://localhost/container/";
    private static final String DOC = "https://localhost/container/doc/";
    private static final String OTHER = "https://localhost/other/";
    private static final String UPLOAD = "https://localhost/uploads/0123456789abcdef";
    private static final String OWNER = "https://localhost/agents/owner/#this";

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
            if (param.getElementsByTagName("param-name").item(0).getTextContent().trim().equals(LDHC.documentContextQuery.getURI()))
                queryString = param.getElementsByTagName("param-value").item(0).getTextContent();
        }

        // the other document's graph claims types and an owner for this document, and types an upload, which has no graph
        // of its own. It claims no containment: the graph store refuses containment of any subject but a graph's own
        // document, which is what lets the ancestors be read over the union graph
        String trig = String.format("""
            <%1$s> { <%1$s> a <%7$sRoot> . }
            <%2$s> { <%2$s> a <%6$sContainer> ; <%8$shas_parent> <%1$s> . }
            <%3$s> { <%3$s> a <%6$sItem> ; <%8$shas_container> <%2$s> ; <%10$sowner> <%9$s> . }
            <%4$s> { <%4$s> a <%6$sItem> ; <%8$shas_container> <%1$s> .
                     <%3$s> a <%5$sFileDataObject>, <%11$s> ; <%10$sowner> <%4$s#agent> .
                     <%12$s> a <%5$sFileDataObject>, <%11$s> . }
            """, ROOT, CONTAINER, DOC, OTHER, NFO, DH, DEF, SIOC, OWNER, ACL, CLASS, UPLOAD);
        dataset = DatasetFactory.create();
        RDFParser.create().source(new StringReader(trig)).lang(Lang.TRIG).parse(dataset);
    }

    private static Set<String> rows(String uri, String rel)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryString);
        pss.setIri(SPIN.THIS_VAR_NAME, uri);

        Set<String> targets = new HashSet<>();
        try (QueryExecution qex = QueryExecution.create(pss.asQuery(), dataset))
        {
            ResultSet results = qex.execSelect();
            results.forEachRemaining(qs ->
            {
                if (qs.getResource(DocumentContext.REL_VAR_NAME).getURI().equals(ACL + rel))
                    targets.add(qs.getResource(DocumentContext.TARGET_VAR_NAME).getURI());
            });
        }
        return targets;
    }

    @Test
    public void documentIsItsOwnAccessToRow()
    {
        assertEquals(Set.of(DOC), rows(DOC, "accessTo"));
    }

    @Test
    public void ancestorsAreTheDefaultRows()
    {
        assertEquals(Set.of(CONTAINER, ROOT), rows(DOC, "default"));
        assertEquals(Set.of(), rows(ROOT, "default"), "the root has no ancestors");
    }

    @Test
    public void typesComeFromTheDocumentsOwnGraph()
    {
        assertEquals(Set.of(DH + "Item"), rows(DOC, "accessToClass"), "another graph cannot add types to a document");
    }

    @Test
    public void ownerComesFromTheDocumentsOwnGraph()
    {
        assertEquals(Set.of(OWNER), rows(DOC, "owner"), "another graph cannot add an owner to a document");
    }

    @Test
    public void uploadIsTypedAFileAndNothingElse()
    {
        assertEquals(Set.of(NFO + "FileDataObject"), rows(UPLOAD, "accessToClass"), "a node without a graph takes no class but nfo:FileDataObject from another graph");
        assertEquals(Set.of(), rows(UPLOAD, "default"));
    }

    @Test
    public void unknownNodeIsOnlyNamed()
    {
        assertEquals(Set.of("https://localhost/missing/"), rows("https://localhost/missing/", "accessTo"));
        assertEquals(Set.of(), rows("https://localhost/missing/", "accessToClass"));
        assertEquals(Set.of(), rows("https://localhost/missing/", "default"));
    }

}
