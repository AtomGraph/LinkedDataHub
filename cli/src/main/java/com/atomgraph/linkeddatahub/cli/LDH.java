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

import com.atomgraph.linkeddatahub.cli.command.Add;
import com.atomgraph.linkeddatahub.cli.command.Create;
import com.atomgraph.linkeddatahub.cli.command.Delete;
import com.atomgraph.linkeddatahub.cli.command.Get;
import com.atomgraph.linkeddatahub.cli.command.Packages;
import com.atomgraph.linkeddatahub.cli.command.Patch;
import com.atomgraph.linkeddatahub.cli.command.Post;
import com.atomgraph.linkeddatahub.cli.command.Put;
import com.atomgraph.linkeddatahub.cli.command.Remove;
import com.atomgraph.linkeddatahub.cli.command.admin.Admin;
import com.atomgraph.linkeddatahub.cli.command.imports.Import;
import org.apache.jena.sys.JenaSystem;
import picocli.AutoComplete;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.ScopeType;

/**
 * Root command of the LinkedDataHub CLI.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "ldh",
    mixinStandardHelpOptions = true,
    versionProvider = LDH.ManifestVersion.class,
    description = "Command line interface for the LinkedDataHub HTTP API.",
    subcommands = {
        Get.class, Post.class, Put.class, Patch.class, Delete.class,
        Create.class, Add.class, Remove.class, Import.class,
        Packages.class, Admin.class,
        AutoComplete.GenerateCompletion.class
    })
public class LDH
{

    @Option(names = "--verbose", scope = ScopeType.INHERIT, description = "Print stack traces of errors")
    boolean verbose;

    /**
     * Reports the version the jar was built at, read from its manifest. Classes loaded outside a jar
     * (an IDE run, the unit tests) have no manifest, hence the fallback.
     */
    static class ManifestVersion implements CommandLine.IVersionProvider
    {

        @Override
        public String[] getVersion()
        {
            String version = LDH.class.getPackage().getImplementationVersion();

            return new String[] { "ldh " + (version != null ? version : "(development build)") };
        }

    }

    /**
     * CLI entry point.
     *
     * @param args command line arguments
     */
    public static void main(String[] args)
    {
        JenaSystem.init();

        CommandLine cmd = new CommandLine(new LDH());
        cmd.setExecutionExceptionHandler(LDH::handleExecutionException);
        System.exit(cmd.execute(args));
    }

    static int handleExecutionException(Exception ex, CommandLine cmdLine, CommandLine.ParseResult parseResult)
    {
        boolean verbose = cmdLine.getCommandSpec().root().userObject() instanceof LDH root && root.verbose;

        cmdLine.getErr().println(cmdLine.getColorScheme().errorText(messageOf(ex)));
        if (verbose) ex.printStackTrace(cmdLine.getErr());

        return CommandLine.ExitCode.SOFTWARE;
    }

    static String messageOf(Throwable ex)
    {
        // unwrap Jersey ProcessingException chains down to the I/O cause, e.g. "Connection refused"
        Throwable cause = ex;
        while (cause.getCause() != null && (cause instanceof jakarta.ws.rs.ProcessingException || cause.getMessage() == null))
            cause = cause.getCause();

        return cause.getMessage() != null ? cause.getMessage() : cause.toString();
    }

}
