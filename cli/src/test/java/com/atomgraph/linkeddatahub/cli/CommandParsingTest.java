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

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.util.List;
import org.junit.jupiter.api.Test;
import picocli.CommandLine;
import picocli.CommandLine.ParseResult;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests for the command tree and argument parsing.
 */
public class CommandParsingTest
{

    static CommandLine commandLine()
    {
        CommandLine cmd = new CommandLine(new LDH());
        cmd.setOut(new PrintWriter(Writer.nullWriter()));
        cmd.setErr(new PrintWriter(Writer.nullWriter()));
        return cmd;
    }

    @Test
    public void commandTreeGroupsByVerb()
    {
        CommandLine root = commandLine();

        List.of("get", "post", "put", "patch", "delete", "create", "add", "remove", "import", "packages", "admin").
            forEach(name -> assertTrue(root.getSubcommands().containsKey(name), name));

        List.of("item", "container").
            forEach(name -> assertTrue(root.getSubcommands().get("create").getSubcommands().containsKey(name), name));

        List.of("view", "construct", "select", "result-set-chart", "file", "generic-service",
                "rdf-import", "csv-import", "object-block", "xhtml-block").
            forEach(name -> assertTrue(root.getSubcommands().get("add").getSubcommands().containsKey(name), name));

        assertTrue(root.getSubcommands().get("remove").getSubcommands().containsKey("block"));

        List.of("list", "add", "remove").
            forEach(name -> assertTrue(root.getSubcommands().get("packages").getSubcommands().containsKey(name), name));

        List.of("rdf", "csv").
            forEach(name -> assertTrue(root.getSubcommands().get("import").getSubcommands().containsKey(name), name));

        CommandLine admin = root.getSubcommands().get("admin");
        List.of("create", "add", "clear", "import", "make-public").
            forEach(name -> assertTrue(admin.getSubcommands().containsKey(name), name));

        List.of("ontology", "group", "authorization").
            forEach(name -> assertTrue(admin.getSubcommands().get("create").getSubcommands().containsKey(name), name));

        List.of("class", "constructor", "select", "property-constraint", "restriction", "ontology-import", "agent").
            forEach(name -> assertTrue(admin.getSubcommands().get("add").getSubcommands().containsKey(name), name));

        assertTrue(admin.getSubcommands().get("clear").getSubcommands().containsKey("ontology"));
        assertTrue(admin.getSubcommands().get("import").getSubcommands().containsKey("ontology"));
    }

    @Test
    public void missingRequiredOptionIsUsageError()
    {
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("create", "item", "--container", "https://localhost:4443/some/"));
    }

    @Test
    public void unknownOptionIsUsageError()
    {
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("get", "--bogus"));
    }

    @Test
    public void bareGroupCommandIsUsageError()
    {
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("admin"));
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("admin", "add"));
    }

    @Test
    public void helpIsRecognizedAtEveryNestingLevel()
    {
        List.of(new String[] { "--help" },
                new String[] { "get", "--help" },
                new String[] { "admin", "--help" },
                new String[] { "add", "--help" },
                new String[] { "import", "--help" },
                new String[] { "admin", "create", "--help" },
                new String[] { "admin", "add", "--help" },
                new String[] { "remove", "block", "--help" },
                new String[] { "import", "csv", "-h" },
                new String[] { "admin", "add", "class", "--help" }).
            forEach(args -> assertEquals(CommandLine.ExitCode.OK, commandLine().execute(args), String.join(" ", args)));
    }

    @Test
    public void helpPrintsTheUsageOfTheCommandItWasAskedOn()
    {
        StringWriter out = new StringWriter();
        CommandLine cmd = commandLine();
        cmd.setOut(new PrintWriter(out));
        cmd.execute("remove", "block", "--help");

        assertTrue(out.toString().startsWith("Usage: ldh remove block"), out.toString());
    }

    @Test
    public void repeatableOptionsAccumulate()
    {
        ParseResult parseResult = commandLine().parseArgs("admin", "create", "group",
            "-f", "cert.p12", "-p", "secret", "-b", "https://admin.localhost:4443/",
            "--name", "Editors",
            "--member", "https://localhost:4443/acl/agents/a/#this",
            "--member", "https://localhost:4443/acl/agents/b/#this");

        ParseResult createGroup = parseResult.subcommand().subcommand().subcommand();
        List<URI> members = createGroup.matchedOption("--member").getValue();
        assertEquals(2, members.size());
    }

    @Test
    public void missingCertOptionsFailValidationAtExecutionTime()
    {
        // cert options have env-var defaults, so they are validated at execution time, not parse time
        assertNotNull(commandLine().parseArgs("delete", "https://localhost:4443/some/"));
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("delete", "https://localhost:4443/some/"));
    }

    @Test
    public void mementoRolesAreMutuallyExclusive()
    {
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("get", "--timemap", "--version", "a1b2c3", "https://localhost:4443/some/"));
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("get", "--timemap", "--timegate", "https://localhost:4443/some/"));
    }

    @Test
    public void datetimeIsOnlyValidWithTheTimeGate()
    {
        assertNotNull(commandLine().parseArgs("get", "--timegate", "--datetime", "2026-08-20T10:00:00Z", "https://localhost:4443/some/"));
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("get",
            "--accept", "text/turtle", "--datetime", "2026-08-20T10:00:00Z", "https://localhost:4443/some/"));
    }

}
