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
import com.atomgraph.linkeddatahub.cli.http.LDHClient;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import com.atomgraph.linkeddatahub.cli.vocab.SD;
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
 * Adds RDF import metadata to a document. Mirrors <code>bin/imports/add-rdf-import.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-rdf-import", description = "Adds RDF import metadata to a document.")
public class AddRDFImport extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the import")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the import (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the import (optional, blank node if not set)")
    private String uri;

    @Option(names = "--query", paramLabel = "QUERY_URI", description = "URI of the transformation CONSTRUCT query (optional)")
    private URI query;

    @Option(names = "--graph", paramLabel = "GRAPH_URI", description = "URI of the target named graph (optional)")
    private URI graph;

    @Option(names = "--file", required = true, paramLabel = "FILE_URI", description = "URI of the uploaded RDF file")
    private URI file;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        core(getClient(), target, uri, title, file, query, graph, description);
        print(target);

        return 0;
    }

    /**
     * Appends the RDF import metadata to the target document.
     *
     * @param client client instance
     * @param target target document URI
     * @param uri import URI (optional)
     * @param title import title
     * @param file uploaded file URI
     * @param query transformation query URI (optional)
     * @param graph target named graph URI (optional)
     * @param description import description (optional)
     */
    public static void core(LDHClient client, URI target, String uri, String title, URI file, URI query, URI graph, String description)
    {
        post(client, target, buildModel(target, uri, title, file, query, graph, description));
    }

    /**
     * Builds the RDF import description.
     *
     * @param target target document URI
     * @param uri import URI (optional)
     * @param title import title
     * @param file uploaded file URI
     * @param query transformation query URI (optional)
     * @param graph target named graph URI (optional)
     * @param description import description (optional)
     * @return import model
     */
    public static Model buildModel(URI target, String uri, String title, URI file, URI query, URI graph, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource rdfImport = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.RDFImport).
            addProperty(DCTerms.title, title).
            addProperty(LDH.file, model.createResource(file.toString()));
        if (graph != null) rdfImport.addProperty(SD.name, model.createResource(graph.toString()));
        if (query != null) rdfImport.addProperty(SPIN.query, model.createResource(query.toString()));
        if (description != null) rdfImport.addProperty(DCTerms.description, description);

        return model;
    }

}
