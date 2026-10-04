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
import com.atomgraph.linkeddatahub.rdf.Views;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Appends a view of a SPARQL SELECT query to a document. Mirrors <code>bin/add-view.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "view", description = "Appends a view to a document.")
public class AddView extends BaseCommand
{

    @Option(names = "--query", required = true, paramLabel = "QUERY_URI", description = "URI of the SELECT query")
    private URI query;

    @Option(names = "--title", paramLabel = "TITLE", description = "Title of the view (optional)")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the view (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the view (optional, blank node if not set)")
    private String uri;

    @Option(names = "--mode", paramLabel = "MODE_URI", description = "URI of the layout mode (optional)")
    private URI mode;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        post(getClient(), target, Views.view(target, uri, query, title, description, mode));
        print(target);

        return 0;
    }

}
