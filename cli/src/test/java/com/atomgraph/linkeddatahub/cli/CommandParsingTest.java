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
    public void commandTreeMirrorsScriptLayout()
    {
        CommandLine root = commandLine();

        List.of("get", "post", "put", "patch", "delete", "create-item", "create-container",
                "add-view", "add-construct", "add-select", "add-result-set-chart", "add-file", "add-generic-service",
                "admin", "content", "imports").
            forEach(name -> assertTrue(root.getSubcommands().containsKey(name), name));

        CommandLine admin = root.getSubcommands().get("admin");
        List.of("ontologies", "acl", "packages", "clear-ontology", "add-ontology-import").
            forEach(name -> assertTrue(admin.getSubcommands().containsKey(name), name));

        List.of("create-ontology", "import-ontology", "add-class", "add-constructor", "add-select",
                "add-property-constraint", "add-restriction").
            forEach(name -> assertTrue(admin.getSubcommands().get("ontologies").getSubcommands().containsKey(name), name));

        List.of("create-group", "create-authorization", "add-agent-to-group", "make-public").
            forEach(name -> assertTrue(admin.getSubcommands().get("acl").getSubcommands().containsKey(name), name));

        List.of("install-package", "uninstall-package").
            forEach(name -> assertTrue(admin.getSubcommands().get("packages").getSubcommands().containsKey(name), name));

        List.of("add-object-block", "add-xhtml-block", "remove-block").
            forEach(name -> assertTrue(root.getSubcommands().get("content").getSubcommands().containsKey(name), name));

        List.of("add-csv-import", "add-rdf-import", "import-csv", "import-rdf").
            forEach(name -> assertTrue(root.getSubcommands().get("imports").getSubcommands().containsKey(name), name));
    }

    @Test
    public void missingRequiredOptionIsUsageError()
    {
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("create-item", "--container", "https://localhost:4443/some/"));
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
        assertEquals(CommandLine.ExitCode.USAGE, commandLine().execute("admin", "acl"));
    }

    @Test
    public void repeatableOptionsAccumulate()
    {
        ParseResult parseResult = commandLine().parseArgs("admin", "acl", "create-group",
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

}
