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
import com.atomgraph.linkeddatahub.cli.http.LDHClient;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
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
 * Adds a SPARQL CONSTRUCT query to a document. Mirrors <code>bin/add-construct.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-construct", description = "Adds a CONSTRUCT query to a document.")
public class AddConstruct extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the query")
    private String title;

    @Option(names = "--query-file", required = true, paramLabel = "ABS_PATH", description = "Path to the file with the query string")
    private Path queryFile;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the query (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the query (optional, blank node if not set)")
    private String uri;

    @Option(names = "--service", paramLabel = "SERVICE_URI", description = "URI of the SPARQL service (optional)")
    private URI service;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        core(getClient(), target, uri, title, Files.readString(queryFile), service, description);
        print(target);

        return 0;
    }

    /**
     * Appends the CONSTRUCT query description to the target document.
     *
     * @param client client instance
     * @param target target document URI
     * @param uri query URI (optional)
     * @param title query title
     * @param queryText query string
     * @param service SPARQL service URI (optional)
     * @param description query description (optional)
     */
    public static void core(LDHClient client, URI target, String uri, String title, String queryText, URI service, String description)
    {
        post(client, target, buildModel(target, uri, SP.Construct, title, queryText, service, description));
    }

    /**
     * Builds a SPIN query description.
     *
     * @param target target document URI
     * @param uri query URI (optional)
     * @param queryType SPIN query class (<code>sp:Construct</code> or <code>sp:Select</code>)
     * @param title query title
     * @param queryText query string
     * @param service SPARQL service URI (optional)
     * @param description query description (optional)
     * @return query model
     */
    public static Model buildModel(URI target, String uri, Resource queryType, String title, String queryText, URI service, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource query = createSubject(model, target, uri).
            addProperty(RDF.type, queryType).
            addProperty(DCTerms.title, title).
            addProperty(SP.text, queryText);
        if (service != null) query.addProperty(LDH.service, model.createResource(service.toString()));
        if (description != null) query.addProperty(DCTerms.description, description);

        return model;
    }

}
