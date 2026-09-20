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
import com.atomgraph.linkeddatahub.cli.http.StubServer.Request;
import com.atomgraph.linkeddatahub.cli.util.Digests;
import java.io.IOException;
import java.io.StringWriter;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import picocli.CommandLine;
import static com.atomgraph.linkeddatahub.cli.CommandOutputTest.commandLine;
import static com.atomgraph.linkeddatahub.cli.CommandOutputTest.keyStorePath;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the output and request contract of <code>push</code>: documents are <code>PUT</code> before
 * the uploads into them are <code>POST</code>ed, every written URL is a line on stdout, progress and
 * skips go to stderr, a dry run sends nothing, and the first error stops the run.
 */
public class PushOutputTest
{

    /** A tree with a root document, a child container with a document and an upload, an ignored file and a hidden one. */
    static Path fixture(Path root) throws IOException
    {
        Files.writeString(root.resolve("root.ttl"), "<> <http://purl.org/dc/terms/title> \"Root\" .\n");
        Files.writeString(root.resolve("a.ttl"), "<> <http://purl.org/dc/terms/title> \"A\" .\n");
        Files.writeString(root.resolve(".hidden"), "");
        Files.createDirectory(root.resolve("a"));
        Files.writeString(root.resolve("a/b.ttl"), "<> <http://purl.org/dc/terms/title> \"B\" .\n");
        Files.writeString(root.resolve("a/image.png"), "not really a PNG");
        Files.writeString(root.resolve("a/ignored.txt"), "ignored");
        Files.writeString(root.resolve("a/.ldhignore"), "ignored.txt\n");
        return root;
    }

    static List<String> expectedURLs(URI base, Path root)
    {
        return List.of(base.toString(), base + "a/", base + "a/b/", base + "uploads/" + Digests.sha1Hex(root.resolve("a/image.png")));
    }

    @Test
    public void pushWritesDocumentsThenUploadsInWalkOrder(@TempDir Path root) throws Exception
    {
        fixture(root);
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("push",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--dir", root.toString(), base.toString());

            assertEquals(0, code, err.toString());
            List<Request> requests = server.getRequests();
            assertEquals(List.of("PUT /", "PUT /a/", "PUT /a/b/", "POST /a/"),
                requests.stream().map(request -> request.method() + " " + request.target()).toList());
            assertTrue(requests.get(2).body().contains(base + "a/b/"), "relative subject was not resolved against the document: " + requests.get(2).body());
            assertTrue(requests.get(3).header("content-type").startsWith("multipart/form-data"), requests.get(3).header("content-type"));
            assertTrue(requests.get(3).body().contains("image.png"), requests.get(3).body());

            assertEquals(expectedURLs(base, root), out.toString().lines().toList());
            assertTrue(err.toString().contains("PUT " + base + " <- root.ttl"), err.toString());
            assertTrue(err.toString().contains("POST " + base + "a/ <- a/image.png"), err.toString());
            assertTrue(err.toString().contains("Skipping a/ignored.txt"), err.toString());
            assertFalse(err.toString().contains(".hidden"), err.toString());
        }
    }

    @Test
    public void dryRunSendsNothingAndNeedsNoCertificate(@TempDir Path root) throws Exception
    {
        fixture(root);
        try (StubServer server = new StubServer())
        {
            server.responds(201, "");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("push", "--dry-run",
                "-b", base.toString(), "--dir", root.toString(), base.toString());

            assertEquals(0, code, err.toString());
            assertTrue(server.getRequests().isEmpty(), "dry run sent " + server.getRequests());
            assertEquals(expectedURLs(base, root), out.toString().lines().toList());
            assertTrue(err.toString().contains("Skipping a/ignored.txt"), err.toString());
        }
    }

    @Test
    public void pushStopsAtTheFirstHttpError(@TempDir Path root) throws Exception
    {
        fixture(root);
        try (StubServer server = new StubServer())
        {
            server.responds(403, "Forbidden by authorization");
            URI base = server.baseURI();
            StringWriter out = new StringWriter(), err = new StringWriter();

            int code = commandLine(out, err).execute("push",
                "-f", keyStorePath().toString(), "-p", "changeit", "-b", base.toString(),
                "--dir", root.toString(), base.toString());

            assertEquals(CommandLine.ExitCode.SOFTWARE, code);
            assertEquals(1, server.getRequests().size(), "the run did not stop at the first error");
            assertEquals("", out.toString(), "a failed write must not print its URL");
            assertTrue(err.toString().contains("HTTP 403"), err.toString());
        }
    }

}
