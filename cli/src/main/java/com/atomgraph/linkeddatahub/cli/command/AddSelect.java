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
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds a SPARQL SELECT query to a document. Mirrors <code>bin/add-select.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-select", description = "Adds a SELECT query to a document.")
public class AddSelect extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the query")
    private String title;

    @Option(names = "--query-file", required = true, paramLabel = "ABS_PATH", description = "Path to the file with the query string")
    private Path queryFile;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the query (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the query (optional, blank node if not set)")
    private String uri;

    @Option(names = "--service", paramLabel = "SERVICE_URI", description = "URI of the SPARQL service (optional)")
    private URI service;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, AddConstruct.buildModel(target, uri, SP.Select, title, Files.readString(queryFile), service, description));
        print(target);

        return 0;
    }

}
