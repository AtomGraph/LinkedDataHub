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
 * Imports CSV data: adds the transformation query, uploads the CSV file and creates the
 * import metadata on the target document. Mirrors <code>bin/imports/import-csv.sh</code>,
 * calling the same steps in-process instead of via subscripts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "import-csv", description = "Imports CSV data using a transformation query.")
public class ImportCSV extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the import")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the import (optional)")
    private String description;

    @Option(names = "--query-file", required = true, paramLabel = "ABS_PATH", description = "Path to the file with the transformation CONSTRUCT query")
    private Path queryFile;

    @Option(names = "--csv-file", required = true, paramLabel = "ABS_PATH", description = "Path to the CSV file")
    private Path csvFile;

    @Option(names = "--delimiter", defaultValue = ",", paramLabel = "CHAR", description = "CSV delimiter character (default: ${DEFAULT-VALUE})")
    private String delimiter;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the import document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());

        String queryId = Slugs.defaultSlug();
        AddConstruct.core(getClient(), target, "#" + queryId, title, Files.readString(queryFile), null, null);
        URI query = target.resolve("#" + queryId);

        URI fileURI = AddFile.core(getClient(), base, target, csvFile, "text/csv", title, null);

        AddCSVImport.core(getClient(), target, null, title, query, fileURI, delimiter, description);
        print(target);

        return 0;
    }

}
