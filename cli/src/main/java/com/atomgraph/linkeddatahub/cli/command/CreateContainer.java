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
import com.atomgraph.linkeddatahub.cli.vocab.AC;
import com.atomgraph.linkeddatahub.cli.vocab.DH;
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import com.atomgraph.linkeddatahub.cli.vocab.SPIN;
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
 * Creates a container document. Mirrors <code>bin/create-container.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "create-container", description = "Creates a container document.")
public class CreateContainer extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the container")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the container (optional)")
    private String description;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--parent", required = true, paramLabel = "PARENT_URI", description = "URI of the parent container")
    private URI parent;

    @Option(names = "--block", paramLabel = "BLOCK_URI", description = "URI of the content block (optional)")
    private URI block;

    @Option(names = "--mode", paramLabel = "MODE_URI", description = "URI of the layout mode of the children view (optional)")
    private URI mode;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        URI doc = URIRewriter.childURI(parent, slug != null ? slug : Slugs.defaultSlug());
        put(getClient(), doc, buildModel(doc, title, description, block, mode));
        print(doc);

        return 0;
    }

    /**
     * Builds the container document model with its first content block: the given block URI,
     * a children view with an explicit mode, or the default children view.
     *
     * @param doc document URI
     * @param title document title
     * @param description document description (optional)
     * @param block content block URI (optional)
     * @param mode children view mode URI (optional, ignored when block is given)
     * @return document model
     */
    public static Model buildModel(URI doc, String title, String description, URI block, URI mode)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource container = model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Container).
            addProperty(DCTerms.title, title);

        if (block != null) container.addProperty(RDF.li(1), model.createResource(block.toString()));
        else if (mode != null) container.addProperty(RDF.li(1), model.createResource().
                addProperty(RDF.type, LDH.Object).
                addProperty(RDF.value, model.createResource().
                    addProperty(RDF.type, LDH.View).
                    addProperty(SPIN.query, LDH.SelectChildren).
                    addProperty(AC.mode, model.createResource(mode.toString()))));
        else container.addProperty(RDF.li(1), model.createResource().
                addProperty(RDF.type, LDH.Object).
                addProperty(RDF.value, LDH.ChildrenView));

        if (description != null) container.addProperty(DCTerms.description, description);

        return model;
    }

}
