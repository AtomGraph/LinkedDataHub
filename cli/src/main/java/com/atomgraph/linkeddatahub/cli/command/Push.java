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

package com.atomgraph.linkeddatahub.cli.command;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.PushPlan;
import com.atomgraph.linkeddatahub.cli.util.PushPlan.Step;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import org.apache.jena.rdf.model.Model;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Parameters;

/**
 * Pushes a directory into the document tree it maps to: RDF files are <code>PUT</code> as documents,
 * other files are uploaded into their directory's document, subdirectories recurse (see
 * {@link PushPlan} for the mapping). Replaces <code>update-folder.sh</code> of the
 * LinkedDataHub-Apps repository.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "push", description = "Pushes a directory of RDF documents and files into the document it maps to, recursively.")
public class Push extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--dir", defaultValue = ".", paramLabel = "DIR", description = "Directory to push (default: current directory)")
    private Path dir;

    @Option(names = "--dry-run", description = "Print what would be written without sending any request")
    private boolean dryRun;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document DIR maps to (must end with /)")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        if (!target.isAbsolute() || !target.toString().endsWith("/")) throw new ParameterException(getSpec().commandLine(), "TARGET_URI must be an absolute URI ending with '/': '" + target + "'");
        if (!Files.isDirectory(dir)) throw new ParameterException(getSpec().commandLine(), "Not a directory: '" + dir + "'");

        for (Step step : PushPlan.plan(dir.toAbsolutePath().normalize(), target))
            execute(step, base);

        return 0;
    }

    /**
     * Executes one step: reports it on standard error, sends its request unless this is a dry run,
     * and prints the written URI on standard output.
     *
     * @param step plan step
     * @param base application base URI
     * @throws IOException file read error
     */
    protected void execute(Step step, URI base) throws IOException
    {
        switch (step.kind())
        {
            case SKIP -> printErr("Skipping " + step.relative());
            case DOCUMENT ->
            {
                printErr("PUT " + step.target() + " <- " + step.relative());
                Model model = readModel(step.contentType(), step.target(), step.file());
                if (!dryRun) put(getClient(), step.target(), model);
                print(step.target());
            }
            case UPLOAD ->
            {
                printErr("POST " + step.target() + " <- " + step.relative());
                String title = step.file().getFileName().toString();
                URI upload = dryRun ? AddFile.uploadURI(base, step.file()) : AddFile.core(getClient(), base, step.target(), step.file(), null, title, null);
                print(upload);
            }
        }
    }

}
