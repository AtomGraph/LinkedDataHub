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
import org.apache.jena.sparql.vocabulary.FOAF;
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
@Command(name = "item", description = "Creates an item document.")
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

    @Option(names = "--primary-topic", paramLabel = "URI", description = "URI of what the document is about, resolved against the document URI (optional)")
    private String primaryTopic;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        URI doc = URIRewriter.childURI(container, slug != null ? slug : Slugs.defaultSlug());
        put(getClient(), doc, buildModel(doc, title, description, primaryTopic));
        print(doc);

        return 0;
    }

    /**
     * Builds the item document model.
     *
     * @param doc document URI
     * @param title document title
     * @param description document description (optional)
     * @param primaryTopic URI of the document's primary topic, relative or absolute (optional)
     * @return document model
     */
    public static Model buildModel(URI doc, String title, String description, String primaryTopic)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource item = model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(DCTerms.title, title);
        if (description != null) item.addProperty(DCTerms.description, description);
        // Resolved against the document, so the conventional fragment topic is "#this" and a
        // document about something described elsewhere takes that resource's absolute URI.
        // Singular because foaf:primaryTopic is an owl:FunctionalProperty: a second value would
        // not mean a second topic, it would entail the two topics are the same resource.
        if (primaryTopic != null) item.addProperty(FOAF.primaryTopic, model.createResource(doc.resolve(primaryTopic).toString()));

        return model;
    }

}
