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
import com.atomgraph.linkeddatahub.cli.vocab.AC;
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
import picocli.CommandLine.Parameters;

/**
 * Appends a view of a SPARQL SELECT query to a document. Mirrors <code>bin/add-view.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-view", description = "Appends a view to a document.")
public class AddView extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

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
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, buildModel(target, uri, query, title, description, mode));
        print(target);

        return 0;
    }

    /**
     * Builds the view description.
     *
     * @param target target document URI
     * @param uri view URI (optional)
     * @param query SELECT query URI
     * @param title view title (optional)
     * @param description view description (optional)
     * @param mode layout mode URI (optional)
     * @return view model
     */
    public static Model buildModel(URI target, String uri, URI query, String title, String description, URI mode)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource view = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.View).
            addProperty(SPIN.query, model.createResource(query.toString()));
        if (title != null) view.addProperty(DCTerms.title, title);
        if (description != null) view.addProperty(DCTerms.description, description);
        if (mode != null) view.addProperty(AC.mode, model.createResource(mode.toString()));

        return model;
    }

}
