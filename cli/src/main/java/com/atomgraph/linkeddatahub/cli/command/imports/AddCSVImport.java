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
 * Adds CSV import metadata to a document. Mirrors <code>bin/imports/add-csv-import.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-csv-import", description = "Adds CSV import metadata to a document.")
public class AddCSVImport extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the import")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the import (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the import (optional, blank node if not set)")
    private String uri;

    @Option(names = "--query", required = true, paramLabel = "QUERY_URI", description = "URI of the transformation CONSTRUCT query")
    private URI query;

    @Option(names = "--file", required = true, paramLabel = "FILE_URI", description = "URI of the uploaded CSV file")
    private URI file;

    @Option(names = "--delimiter", defaultValue = ",", paramLabel = "CHAR", description = "CSV delimiter character (default: ${DEFAULT-VALUE})")
    private String delimiter;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        core(getClient(), target, uri, title, query, file, delimiter, description);
        print(target);

        return 0;
    }

    /**
     * Appends the CSV import metadata to the target document.
     *
     * @param client client instance
     * @param target target document URI
     * @param uri import URI (optional)
     * @param title import title
     * @param query transformation query URI
     * @param file uploaded file URI
     * @param delimiter CSV delimiter
     * @param description import description (optional)
     */
    public static void core(LDHClient client, URI target, String uri, String title, URI query, URI file, String delimiter, String description)
    {
        post(client, target, buildModel(target, uri, title, query, file, delimiter, description));
    }

    /**
     * Builds the CSV import description.
     *
     * @param target target document URI
     * @param uri import URI (optional)
     * @param title import title
     * @param query transformation query URI
     * @param file uploaded file URI
     * @param delimiter CSV delimiter
     * @param description import description (optional)
     * @return import model
     */
    public static Model buildModel(URI target, String uri, String title, URI query, URI file, String delimiter, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource csvImport = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.CSVImport).
            addProperty(DCTerms.title, title).
            addProperty(SPIN.query, model.createResource(query.toString())).
            addProperty(LDH.file, model.createResource(file.toString())).
            addProperty(LDH.delimiter, delimiter);
        if (description != null) csvImport.addProperty(DCTerms.description, description);

        return model;
    }

}
