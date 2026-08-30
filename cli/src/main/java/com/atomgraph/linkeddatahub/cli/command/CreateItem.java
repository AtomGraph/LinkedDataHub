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
import com.atomgraph.linkeddatahub.cli.util.Slugs;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import com.atomgraph.linkeddatahub.cli.vocab.DH;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Creates an item document. Mirrors <code>bin/create-item.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "create-item", description = "Creates an item document.")
public class CreateItem extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the item")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the item (optional)")
    private String description;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--container", required = true, paramLabel = "CONTAINER_URI", description = "URI of the parent container")
    private URI container;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        URI doc = URIRewriter.childURI(container, slug != null ? slug : Slugs.defaultSlug());
        put(getClient(), doc, buildModel(doc, title, description));
        print(doc);

        return 0;
    }

    /**
     * Builds the item document model.
     *
     * @param doc document URI
     * @param title document title
     * @param description document description (optional)
     * @return document model
     */
    public static Model buildModel(URI doc, String title, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource item = model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(DCTerms.title, title);
        if (description != null) item.addProperty(DCTerms.description, description);

        return model;
    }

}
