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

package com.atomgraph.linkeddatahub.cli.command.admin;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.sparql.Updates;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds an <code>owl:imports</code> statement to an ontology. Mirrors <code>bin/admin/add-ontology-import.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-ontology-import", description = "Adds an owl:imports statement to an ontology.")
public class AddOntologyImport extends BaseCommand
{

    @Option(names = "--import", required = true, paramLabel = "IMPORT_URI", description = "URI of the imported ontology")
    private URI importURI;

    @Parameters(paramLabel = "ONTOLOGY_DOC_URI", description = "URI of the ontology document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        HttpException.check(target, getClient().patch(target, Updates.insertOntologyImport(target, importURI))).close();

        return 0;
    }

}
