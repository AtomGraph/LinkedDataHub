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
import com.atomgraph.linkeddatahub.rdf.Documents;
import com.atomgraph.linkeddatahub.rdf.Slugs;
import com.atomgraph.linkeddatahub.rdf.URIs;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;

/**
 * Creates an item document, never replacing one: the write carries <code>If-None-Match: *</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "item", description = "Creates an item document. Fails if a document already exists at its URI, which is left as it is, unless --if-absent is given.")
public class CreateItem extends BaseCommand
{

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the item")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the item (optional)")
    private String description;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--container", required = true, paramLabel = "CONTAINER_URI", description = "URI of the parent container")
    private URI container;

    @Option(names = "--primary-topic", paramLabel = "URI", description = "URI of what the document is about, resolved against the document URI (optional)")
    private String primaryTopic;

    @Option(names = "--if-absent", description = "Succeed without writing when a document already exists at the URI, leaving it as it is (like mkdir -p); without it, an existing document fails the command")
    private boolean ifAbsent;

    @Override
    public Integer call() throws Exception
    {
        URI doc = URIs.childURI(container, slug != null ? slug : Slugs.defaultSlug());
        create(getClient(), doc, Documents.item(doc, title, description, primaryTopic), ifAbsent);
        print(doc);

        return 0;
    }

}
