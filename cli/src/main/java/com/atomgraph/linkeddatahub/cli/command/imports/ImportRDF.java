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

package com.atomgraph.linkeddatahub.cli.command.imports;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.command.AddConstruct;
import com.atomgraph.linkeddatahub.cli.command.AddFile;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.Slugs;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Imports RDF data: optionally adds a transformation query, uploads the RDF file and creates
 * the import metadata on the target document. Mirrors <code>bin/imports/import-rdf.sh</code>,
 * calling the same steps in-process instead of via subscripts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "import-rdf", description = "Imports RDF data, optionally using a transformation query.")
public class ImportRDF extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the import")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the import (optional)")
    private String description;

    @Option(names = "--query-file", paramLabel = "ABS_PATH", description = "Path to the file with the transformation CONSTRUCT query (optional)")
    private Path queryFile;

    @Option(names = "--rdf-file", required = true, paramLabel = "ABS_PATH", description = "Path to the RDF file")
    private Path rdfFile;

    @Option(names = "--content-type", required = true, paramLabel = "MEDIA_TYPE", description = "Media type of the RDF file (e.g. text/turtle)")
    private String contentType;

    @Option(names = "--graph", paramLabel = "GRAPH_URI", description = "URI of the target named graph (optional)")
    private URI graph;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the import document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());

        URI query = null;
        if (queryFile != null)
        {
            String queryId = Slugs.defaultSlug();
            AddConstruct.core(getClient(), target, "#" + queryId, title, Files.readString(queryFile), null, null);
            query = target.resolve("#" + queryId);
        }

        URI fileURI = AddFile.core(getClient(), base, target, rdfFile, contentType, title, null);

        String importId = Slugs.defaultSlug();
        AddRDFImport.core(getClient(), target, "#" + importId, title, fileURI, query, query == null ? graph : null, description);
        print(target);

        return 0;
    }

}
