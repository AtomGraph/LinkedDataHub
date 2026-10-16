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

package com.atomgraph.linkeddatahub.cli;

import static com.atomgraph.linkeddatahub.cli.CommandOutputTest.commandLine;
import static com.atomgraph.linkeddatahub.cli.CommandOutputTest.keyStorePath;
import com.atomgraph.linkeddatahub.cli.http.StubServer;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Tests that admin commands find the admin application from the end-user base's <code>lds:admin</code> link, that a
 * proxy keeps the logical <code>Host</code>, and that <code>import ontology --file</code> replaces the namespace
 * ontology document keeping its header.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AdminDiscoveryTest
{

    private static final String LDS = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#";

    private static String link(URI target, String rel)
    {
        return "<" + target + ">; rel=\"" + rel + "\"";
    }

    private static List<String> methodsAndTargets(StubServer server)
    {
        return server.getRequests().stream().map(r -> r.method() + " " + r.target()).collect(Collectors.toList());
    }

    @Test
    public void clearFollowsAdminLinkFromEndUserBase() throws Exception
    {
        try (StubServer endUser = new StubServer(); StubServer admin = new StubServer())
        {
            endUser.respondsWithHeader("Link", link(admin.baseURI(), LDS + "admin"));
            admin.responds(200, "");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("admin", "clear", "ontology", "-c", keyStorePath().toString(), "-p", "changeit",
                endUser.baseURI().toString());

            assertEquals(0, code, err.toString());
            assertEquals("HEAD", endUser.getLastMethod());
            assertEquals("POST", admin.getLastMethod());
            assertEquals("/clear", admin.getLastTarget());
        }
    }

    @Test
    public void adminBaseLinkingItselfIsAdminBase() throws Exception
    {
        try (StubServer admin = new StubServer())
        {
            admin.respondsWithHeader("Link", link(admin.baseURI(), LDS + "admin")).responds(200, "");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("admin", "clear", "ontology", "-c", keyStorePath().toString(), "-p", "changeit",
                admin.baseURI().toString());

            assertEquals(0, code, err.toString());
            assertEquals(List.of("HEAD /", "POST /clear"), methodsAndTargets(admin));
        }
    }

    @Test
    public void baseWithoutAdminLinkIsRefused() throws Exception
    {
        try (StubServer endUser = new StubServer())
        {
            endUser.responds(200, "");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("admin", "clear", "ontology", "-c", keyStorePath().toString(), "-p", "changeit",
                endUser.baseURI().toString());

            assertEquals(1, code);
            assertTrue(err.toString().contains("advertises no lds:admin link"), err.toString());
            assertEquals(List.of("HEAD /"), methodsAndTargets(endUser));
        }
    }

    @Test
    public void proxyKeepsLogicalHostAndPath() throws Exception
    {
        try (StubServer proxy = new StubServer())
        {
            proxy.respondsWithType("application/n-triples").responds(200, "<http://a> <http://b> <http://c> .");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get", "-c", keyStorePath().toString(), "-p", "changeit",
                "--accept", "application/n-triples", "--proxy", proxy.baseURI().toString(), "http://admin.example.org:4443/a%20b/?c=d");

            assertEquals(0, code, err.toString());
            assertEquals("/a%20b/?c=d", proxy.getLastTarget());
            assertEquals("admin.example.org:4443", proxy.getLastHeader("Host"));
        }
    }

    @Test
    public void importOntologyFileReplacesDocumentKeepingHeader(@TempDir Path dir) throws Exception
    {
        try (StubServer endUser = new StubServer(); StubServer admin = new StubServer())
        {
            URI ontology = endUser.baseURI().resolve("ns#");
            URI doc = admin.baseURI().resolve("ontologies/namespace/");
            endUser.respondsWithHeader("Link", link(admin.baseURI(), LDS + "admin") + ", " + link(ontology, LDS + "ontology"));
            // the seeded document, with a term from a previous install that the file no longer has
            admin.respondsTo("/ontologies/namespace/", 200, "text/turtle",
                "<" + doc + "> a <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ; " +
                "<http://purl.org/dc/terms/title> \"Namespace\" ; <http://xmlns.com/foaf/0.1/primaryTopic> <" + ontology + "> .\n" +
                "<" + ontology + "> a <http://www.w3.org/2002/07/owl#Ontology> ; <http://www.w3.org/2002/07/owl#imports> <https://w3id.org/atomgraph/linkeddatahub/default#> .\n" +
                "<" + ontology.resolve("#Removed") + "> a <http://www.w3.org/2002/07/owl#Class> .\n");
            admin.responds(200, "");

            Path file = dir.resolve("ns.ttl");
            Files.writeString(file, "@prefix : <#> . @prefix owl: <http://www.w3.org/2002/07/owl#> . : a owl:Ontology . :Book a owl:Class .");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("admin", "import", "ontology", "-c", keyStorePath().toString(), "-p", "changeit",
                "--file", file.toString(), endUser.baseURI().toString());

            assertEquals(0, code, err.toString());
            assertEquals(doc.toString(), out.toString().strip());

            StubServer.Request put = admin.getRequests().stream().filter(r -> r.method().equals("PUT")).findFirst().orElseThrow();
            Model written = ModelFactory.createDefaultModel();
            RDFParser.create().source(new StringReader(put.body())).lang(Lang.TURTLE).base(doc.toString()).parse(written);

            assertTrue(written.contains(written.createResource(ontology.resolve("#Book").toString()), RDF.type, OWL.Class), "the file's term");
            assertTrue(written.contains(written.createResource(ontology.toString()), OWL.imports, written.createResource("https://w3id.org/atomgraph/linkeddatahub/default#")), "the seeded header");
            assertTrue(written.contains(written.createResource(doc.toString()), null, (org.apache.jena.rdf.model.RDFNode)null), "the document's own description");
            assertFalse(written.contains(written.createResource(ontology.resolve("#Removed").toString()), null, (org.apache.jena.rdf.model.RDFNode)null), "a term the file dropped");

            StubServer.Request clear = admin.getRequests().stream().filter(r -> r.method().equals("POST")).findFirst().orElseThrow();
            assertEquals("/clear", clear.target());
            assertTrue(clear.body().contains("uri=" + java.net.URLEncoder.encode(ontology.toString(), java.nio.charset.StandardCharsets.UTF_8)), clear.body());
        }
    }

    @Test
    public void importOntologyFileNeedsEndUserBase(@TempDir Path dir) throws Exception
    {
        try (StubServer admin = new StubServer())
        {
            admin.respondsWithHeader("Link", link(admin.baseURI(), LDS + "admin")).responds(200, "");
            Path file = dir.resolve("ns.ttl");
            Files.writeString(file, "<#> a <http://www.w3.org/2002/07/owl#Ontology> .");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("admin", "import", "ontology", "-c", keyStorePath().toString(), "-p", "changeit",
                "--file", file.toString(), admin.baseURI().toString());

            assertEquals(2, code);
            assertTrue(err.toString().contains("end-user base"), err.toString());
        }
    }

    @Test
    public void importCsvPrintsTheImportURI(@TempDir Path dir) throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(200, "");
            Path query = Files.writeString(dir.resolve("q.rq"), "CONSTRUCT WHERE { ?s ?p ?o }");
            Path csv = Files.writeString(dir.resolve("d.csv"), "a,b\n1,2\n");
            URI target = server.baseURI().resolve("items/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("import", "csv", "-c", keyStorePath().toString(), "-p", "changeit",
                "--title", "Items", "--query-file", query.toString(), "--csv-file", csv.toString(), target.toString());

            assertEquals(0, code, err.toString());
            String printed = out.toString().strip();
            assertTrue(printed.matches(java.util.regex.Pattern.quote(target.toString()) + "#[0-9a-f-]{36}"), printed);
            // the printed import is the resource the import request describes
            String importPost = server.getRequests().stream().filter(r -> r.method().equals("POST") && r.body().contains("CSVImport")).
                map(StubServer.Request::body).findFirst().orElseThrow();
            assertTrue(importPost.contains(printed.substring(printed.indexOf('#'))), importPost);
        }
    }

}
