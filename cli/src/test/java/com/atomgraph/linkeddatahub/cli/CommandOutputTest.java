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
import java.nio.file.Path;
import java.nio.file.Paths;
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
 * <code>item=$(ldh create-item ...)</code> breaks the moment anything else reaches stdout, and the
 * http-tests consume that substitution in dozens of places.
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

            int code = commandLine(out, err).execute("create-container",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--title", "Test", "--slug", "test", "--parent", base.toString());

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

            commandLine(out, err).execute("create-container",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--title", "Test", "--slug", "test", "--parent", base.toString());

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

            int code = commandLine(out, err).execute("create-container",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--title", "Ö", "--slug", "ö x", "--parent", base.toString());

            assertEquals(0, code);
            assertEquals(base + "%C3%B6%20x/", out.toString().strip());
            assertEquals("/%C3%B6%20x/", server.getLastTarget());
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
                "-f", keyStorePath().toString(), "-p", "changeit", "-t", "text/turtle", target.toString());

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
                "-f", keyStorePath().toString(), "-p", "changeit", target.toString());

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
                "-f", keyStorePath().toString(), "-p", "changeit", target.toString());

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

            int code = commandLine(out, err).execute("create-container",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--title", "Test", "--slug", "test", "--parent", base.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals("", out.toString(), "a failed command must print nothing on stdout");
            assertTrue(err.toString().contains("HTTP 403"), err.toString());
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

        int code = commandLine(out, err).execute("create-container",
            "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
            "--title", "Test", "--slug", "test", "--parent", base.toString());

        assertEquals(CommandLine.ExitCode.SOFTWARE, code);
        assertEquals("", out.toString(), "a failed command must print nothing on stdout");
        assertTrue(err.toString().contains("Connection refused"), err.toString());
    }

}
