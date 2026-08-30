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

package com.atomgraph.linkeddatahub.cli.command.admin.ontologies;

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
 * Adds a SPARQL SELECT query to an ontology. Mirrors <code>bin/admin/ontologies/add-select.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-select", description = "Adds a SELECT query to an ontology.")
public class AddSelect extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the query")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the query (optional)")
    private String comment;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the query (optional, blank node if not set)")
    private String uri;

    @Option(names = "--query-file", required = true, paramLabel = "ABS_PATH", description = "Path to the file with the query string")
    private Path queryFile;

    @Option(names = "--service", paramLabel = "SERVICE_URI", description = "URI of the SPARQL service (optional)")
    private URI service;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the ontology document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, AddConstructor.buildModel(target, uri, SP.Select, label, Files.readString(queryFile), service, comment));
        print(target);

        return 0;
    }

}
