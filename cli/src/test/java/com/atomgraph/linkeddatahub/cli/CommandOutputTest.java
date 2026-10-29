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

import com.atomgraph.linkeddatahub.cli.http.StubServer;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import org.junit.jupiter.api.Test;
import picocli.CommandLine;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the output contract the shell pipelines depend on: a command that creates or appends to a
 * document prints its URL as the only line on stdout, diagnostics go to stderr, and an HTTP error
 * status leaves stdout empty and exits 1.
 *
 * <code>item=$(ldh create item ...)</code> breaks the moment anything else reaches stdout, and the
 * tests/http consumes that substitution in dozens of places.
 */
public class CommandOutputTest
{

    static Path keyStorePath() throws Exception
    {
        return Paths.get(CommandOutputTest.class.getResource("/test-keystore.p12").toURI());
    }

    static CommandLine commandLine(StringWriter out, StringWriter err)
    {
        CommandLine cmd = new CommandLine(new LDH());
        cmd.setOut(new PrintWriter(out, true));
        cmd.setErr(new PrintWriter(err, true));
        cmd.setExecutionExceptionHandler(LDH::handleExecutionException);
        return cmd;
    }

    @Test
    public void createdURLIsTheOnlyLineOnStdout() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit",                 "--title", "Test", "--slug", "test", "--parent", base.toString());

            assertEquals(0, code);
            assertEquals(base + "test/", out.toString().strip());
            assertEquals(1, out.toString().strip().lines().count(), "stdout carries more than the created URL");
            assertEquals("", err.toString(), "stderr is not empty on success");
        }
    }

    @Test
    public void createdURLMatchesTheDocumentActuallyWritten() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit",                 "--title", "Test", "--slug", "test", "--parent", base.toString());

            assertEquals("PUT", server.getLastMethod());
            assertEquals("/test/", server.getLastTarget());
            assertTrue(server.getLastBody().contains("Test"), server.getLastBody());
        }
    }

    @Test
    public void slugIsPercentEncodedInBothURLAndRequest() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit",                 "--title", "Ö", "--slug", "ö x", "--parent", base.toString());

            assertEquals(0, code);
            assertEquals(base + "%C3%B6%20x/", out.toString().strip());
            assertEquals("/%C3%B6%20x/", server.getLastTarget());
        }
    }

    @Test
    public void createNeverQuotesAnExistingDocumentsState() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "item",
                "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Test", "--slug", "test", "--container", base.toString());

            assertEquals(0, code);
            assertEquals(List.of("PUT"), server.getRequests().stream().map(StubServer.Request::method).toList(),
                "a create reads no entity tag first: quoting one would let it replace the document");
            assertEquals("*", server.getLastHeader("If-None-Match"));
            assertNull(server.getLastHeader("If-Match"));
        }
    }

    @Test
    public void putQuotesTheDocumentsStateButCreateDoesNot() throws Exception
    {
        InputStream in = System.in;
        try (StubServer server = new StubServer())
        {
            // a document that exists: the server tags it
            server.responds(200, "").respondsWithHeader("ETag", "\"v1\"");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            System.setIn(new ByteArrayInputStream("<> <http://purl.org/dc/terms/title> \"Replaced\" ."
                .getBytes(StandardCharsets.UTF_8)));
            assertEquals(0, commandLine(out, err).execute("put",
                "-c", keyStorePath().toString(), "-p", "changeit", "-t", "text/turtle", base + "test/"));
            assertEquals("\"v1\"", server.getLastHeader("If-Match"), "a replace says which state it replaces");
            assertNull(server.getLastHeader("If-None-Match"));

            int requestsBefore = server.getRequests().size();
            assertEquals(0, commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Test", "--slug", "test", "--parent", base.toString()));
            assertEquals(requestsBefore + 1, server.getRequests().size(), "a create reads no entity tag first");
            assertNull(server.getLastHeader("If-Match"), "quoting the tag would let the create replace the document");
            assertEquals("*", server.getLastHeader("If-None-Match"));
        }
        finally
        {
            System.setIn(in);
        }
    }

    @Test
    public void createOverAnExistingDocumentFails() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(412, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Test", "--slug", "test", "--parent", base.toString());

            assertEquals(1, code);
            assertEquals("", out.toString(), "a create that wrote nothing prints no URL");
            assertTrue(err.toString().contains("already exists"), err.toString());
        }
    }

    @Test
    public void createIfAbsentAcceptsAnExistingDocument() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(412, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Test", "--slug", "test", "--parent", base.toString(),
                "--if-absent");

            assertEquals(0, code);
            assertEquals(base + "test/", out.toString().strip(), "the existing document's URL is the result, as a created one's would be");
            assertEquals("", err.toString());
            assertEquals(1, server.getRequests().size(), "the existing document is not written to");
        }
    }

    @Test
    public void putReadsRDFFromStdinResolvingAgainstTheTarget() throws Exception
    {
        InputStream in = System.in;
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI target = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            // a relative subject, as the scripts piped through `turtle --base`
            System.setIn(new ByteArrayInputStream("<> <http://purl.org/dc/terms/title> \"Piped\" ."
                .getBytes(StandardCharsets.UTF_8)));

            int code = commandLine(out, err).execute("put",
                "-c", keyStorePath().toString(), "-p", "changeit", "-t", "text/turtle", target.toString());

            assertEquals(0, code);
            assertEquals("PUT", server.getLastMethod());
            assertTrue(server.getLastBody().contains(target.toString()), "relative subject was not resolved against the target: " + server.getLastBody());
            assertTrue(server.getLastBody().contains("Piped"), server.getLastBody());
            assertEquals(target.toString(), out.toString().strip());
        }
        finally
        {
            System.setIn(in);
        }
    }

    @Test
    public void putReadsRDFFromAFileTypedByItsExtension() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI target = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            Path file = Files.createTempFile("categories", ".ttl");
            Files.writeString(file, "<> <http://purl.org/dc/terms/title> \"Filed\" .");
            try
            {
                int code = commandLine(out, err).execute("put",
                    "-c", keyStorePath().toString(), "-p", "changeit", target.toString(), file.toString());

                assertEquals(0, code);
                assertEquals("PUT", server.getLastMethod());
                assertTrue(server.getLastBody().contains("Filed"), server.getLastBody());
                assertEquals(target.toString(), out.toString().strip());
            }
            finally
            {
                Files.deleteIfExists(file);
            }
        }
    }

    @Test
    public void patchSendsTheStdinUpdateVerbatim() throws Exception
    {
        InputStream in = System.in;
        try (StubServer server = new StubServer())
        {
            server.responds(204, "");
            URI target = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            String update = "PREFIX dct: <http://purl.org/dc/terms/>\nDELETE WHERE { ?s dct:title ?o }";
            System.setIn(new ByteArrayInputStream(update.getBytes(StandardCharsets.UTF_8)));

            int code = commandLine(out, err).execute("patch",
                "-c", keyStorePath().toString(), "-p", "changeit", target.toString());

            assertEquals(0, code);
            assertEquals("PATCH", server.getLastMethod());
            assertEquals(update, server.getLastBody());
        }
        finally
        {
            System.setIn(in);
        }
    }

    @Test
    public void patchRejectsAMalformedUpdateBeforeSending() throws Exception
    {
        InputStream in = System.in;
        try (StubServer server = new StubServer())
        {
            server.responds(204, "");
            URI target = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            System.setIn(new ByteArrayInputStream("DELETE WHERE { this is not SPARQL".getBytes(StandardCharsets.UTF_8)));

            int code = commandLine(out, err).execute("patch",
                "-c", keyStorePath().toString(), "-p", "changeit", target.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertNull(server.getLastMethod(), "a malformed update must not reach the server");
        }
        finally
        {
            System.setIn(in);
        }
    }

    @Test
    public void httpErrorStatusExitsOneWithEmptyStdout() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(403, "Forbidden by authorization");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "container",
                "-c", keyStorePath().toString(), "-p", "changeit",                 "--title", "Test", "--slug", "test", "--parent", base.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals("", out.toString(), "a failed command must print nothing on stdout");
            assertTrue(err.toString().contains("HTTP 403"), err.toString());
        }
    }

    @Test
    public void putAnsweredWithARedirectExitsOneNamingTheLocation() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI target = server.baseURI().resolve("some");
            server.responds(308, "").respondsWithHeader("Location", target + "/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            Path file = Files.createTempFile("redirected", ".ttl");
            Files.writeString(file, "<> <http://purl.org/dc/terms/title> \"Redirected\" .");
            try
            {
                int code = commandLine(out, err).execute("put",
                    "-c", keyStorePath().toString(), "-p", "changeit", target.toString(), file.toString());

                assertEquals(CommandLine.ExitCode.SOFTWARE, code);
                assertEquals("", out.toString(), "a PUT that wrote nothing must not print the URI as if it had");
                assertTrue(err.toString().contains("HTTP 308"), err.toString());
                assertTrue(err.toString().contains("Location: " + target + "/"), err.toString());
            }
            finally
            {
                Files.deleteIfExists(file);
            }
        }
    }

    @Test
    public void createAnsweredWithARedirectExitsOneWithEmptyStdout() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI base = server.baseURI();
            server.responds(308, "").respondsWithHeader("Location", base + "test/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("create", "item",
                "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Test", "--slug", "test", "--container", base.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals("", out.toString(), "a failed command must print nothing on stdout");
        }
    }

    @Test
    public void getAnsweredWithARedirectExitsOne() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI target = server.baseURI().resolve("some");
            server.responds(301, "").respondsWithHeader("Location", target + "/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit", "--accept", "text/turtle", target.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals("", out.toString(), "a redirect has no body to print");
        }
    }

    @Test
    public void headReportsARedirectAndExitsZero() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI target = server.baseURI().resolve("some");
            server.responds(308, "").respondsWithHeader("Location", target + "/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit", "--head", "--accept", "text/turtle", target.toString());

            assertEquals(0, code);
            assertTrue(out.toString().startsWith("HTTP 308"), out.toString());
        }
    }

    @Test
    public void postAnsweredWithSeeOtherSucceeds() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI target = server.baseURI().resolve("some/");
            server.responds(303, "").respondsWithHeader("Location", target + "result/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            Path file = Files.createTempFile("appended", ".ttl");
            Files.writeString(file, "<> <http://purl.org/dc/terms/title> \"Appended\" .");
            try
            {
                int code = commandLine(out, err).execute("post",
                    "-c", keyStorePath().toString(), "-p", "changeit", target.toString(), file.toString());

                assertEquals(0, code, err.toString());
                assertEquals("POST", server.getLastMethod());
            }
            finally
            {
                Files.deleteIfExists(file);
            }
        }
    }

    @Test
    public void addFileAppendsWithAMultipartPost() throws Exception
    {
        assertAddFileSends(false, "POST");
    }

    @Test
    public void addFileReplaceSendsAMultipartPut() throws Exception
    {
        assertAddFileSends(true, "PUT");
    }

    private void assertAddFileSends(boolean replace, String method) throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(204, "");
            URI target = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            Path file = Files.createTempFile("upload", ".txt");
            Files.writeString(file, "uploaded");
            try
            {
                List<String> args = new java.util.ArrayList<>(List.of("add", "file",
                    "-c", keyStorePath().toString(), "-p", "changeit", "--title", "Upload", "--file", file.toString(), "--content-type", "text/plain"));
                if (replace) args.add("--replace");
                args.add(target.toString());

                int code = commandLine(out, err).execute(args.toArray(String[]::new));

                assertEquals(0, code, err.toString());
                assertEquals(method, server.getLastMethod());
                assertTrue(server.getLastHeader("Content-Type").startsWith("multipart/form-data"), server.getLastHeader("Content-Type"));
                assertTrue(out.toString().strip().startsWith(target.resolve("/uploads/").toString()), out.toString());
            }
            finally
            {
                Files.deleteIfExists(file);
            }
        }
    }

    @Test
    public void connectionFailureExitsOneWithEmptyStdout() throws Exception
    {
        URI base;
        try (StubServer server = new StubServer())
        {
            base = server.baseURI(); // port is free again once the server is closed
        }

        StringWriter out = new StringWriter(), err = new StringWriter();

        int code = commandLine(out, err).execute("create", "container",
            "-c", keyStorePath().toString(), "-p", "changeit",             "--title", "Test", "--slug", "test", "--parent", base.toString());

        assertEquals(CommandLine.ExitCode.SOFTWARE, code);
        assertEquals("", out.toString(), "a failed command must print nothing on stdout");
        assertTrue(err.toString().contains("Connection refused"), err.toString());
    }

    @Test
    public void timeGatePrintsTheMementoURIAsTheOnlyLineOnStdout() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI base = server.baseURI();
            server.responds(302, "").respondsWithHeader("Location", base + "some/?version=a1b2c3");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit",
                "--timegate", "--datetime", "2026-08-20T10:00:00Z", base.resolve("some/").toString());

            assertEquals(0, code);
            assertEquals(base + "some/?version=a1b2c3", out.toString().strip());
            assertEquals(1, out.toString().strip().lines().count(), "stdout carries more than the Memento URI");
            assertEquals("", err.toString(), "stderr is not empty on success");
            assertEquals("/some/?timegate", server.getLastTarget());
            assertEquals("Thu, 20 Aug 2026 10:00:00 GMT", server.getLastHeader("Accept-Datetime"));
        }
    }

    @Test
    public void aBareTimeGateNegotiatesWithoutADatetime() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            URI base = server.baseURI();
            server.responds(302, "").respondsWithHeader("Location", base + "some/?version=a1b2c3");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit",
                "--timegate", base.resolve("some/").toString());

            assertEquals(0, code);
            assertNull(server.getLastHeader("Accept-Datetime"), "a bare --timegate must not send Accept-Datetime");
        }
    }

    @Test
    public void aTimeGateThatDoesNotRedirectExitsOneWithEmptyStdout() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(200, "");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit",
                "--timegate", server.baseURI().resolve("some/").toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals("", out.toString(), "a failed command must print nothing on stdout");
        }
    }

    @Test
    public void mementoOptionsAddressTheDocumentsOwnQueryParams() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(200, "");
            URI doc = server.baseURI().resolve("some/");
            StringWriter out = new StringWriter(), err = new StringWriter();

            assertEquals(0, commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit",
                "--accept", "text/turtle", "--version", "a1b2c3", doc.toString()));
            assertEquals("/some/?version=a1b2c3", server.getLastTarget());

            assertEquals(0, commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit",
                "--accept", "text/turtle", "--timemap", doc.toString()));
            assertEquals("/some/?timemap", server.getLastTarget());
        }
    }

    @Test
    public void acceptIsRequiredForEverythingButTheTimeGate() throws Exception
    {
        try (StubServer server = new StubServer())
        {
            server.responds(200, "");
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("get",
                "-c", keyStorePath().toString(), "-p", "changeit", server.baseURI().toString());

            assertEquals(CommandLine.ExitCode.USAGE, code);
            assertNull(server.getLastMethod(), "a request went out without a requested media type");
        }
    }

    @Test
    public void listPackagesMarksTheImportedOnes() throws Exception
    {
        String settings = """
            @prefix ldh: <https://w3id.org/atomgraph/linkeddatahub#> .
            <urn:linkeddatahub:apps/end-user> ldh:import <https://packages.linkeddatahub.com/editor/taxonomy/#this> .
            """;
        String catalog = """
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dct="http://purl.org/dc/terms/">
              <rdf:Description rdf:about="https://packages.linkeddatahub.com/">
                <rdfs:member rdf:resource="https://packages.linkeddatahub.com/editor/taxonomy/#this"/>
                <rdfs:member rdf:resource="https://packages.linkeddatahub.com/foaf/#this"/>
              </rdf:Description>
              <rdf:Description rdf:about="https://packages.linkeddatahub.com/editor/taxonomy/#this">
                <dct:title>Taxonomy Editor</dct:title>
              </rdf:Description>
              <rdf:Description rdf:about="https://packages.linkeddatahub.com/foaf/#this">
                <dct:title>FOAF</dct:title>
              </rdf:Description>
            </rdf:RDF>
            """;

        try (StubServer server = new StubServer())
        {
            server.respondsTo("/settings", 200, "text/turtle", settings);
            server.respondsTo("/", 200, "application/rdf+xml", catalog);
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("packages", "list",
                "-c", keyStorePath().toString(), "-p", "changeit", base.toString());

            assertEquals(0, code);
            assertEquals(List.of("installed\thttps://packages.linkeddatahub.com/editor/taxonomy/#this\tTaxonomy Editor",
                                 "available\thttps://packages.linkeddatahub.com/foaf/#this\tFOAF"),
                out.toString().lines().toList());
            assertEquals("", err.toString(), "stderr is not empty on success");
            // the registry is not the application's own URI, so the catalog is read through the proxy
            assertEquals("/?uri=https%3A%2F%2Fpackages.linkeddatahub.com%2F", server.getLastTarget());
        }
    }

}
