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

package com.atomgraph.linkeddatahub.cli.command.admin.ontologies;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Imports an external ontology into a document: the vocabulary itself, the class constructors derived
 * from it, and a <code>foaf:primaryTopic</code> naming what the document is about.
 * Mirrors <code>bin/admin/ontologies/import-ontology.sh</code>.
 *
 * The vocabulary is fetched through the Linked Data proxy and stays in the target, which is what makes
 * the import an import: the graph carries the vocabulary's own header, so resolving its URI finds this
 * document with the derived annotations on it. The document remains a <code>dh:Item</code> and never
 * claims to be the ontology. The same shape the browser's import produces, and the one a materialized
 * package ontology has.
 *
 * The base URI is the base of the <em>admin</em> application.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "ontology", description = "Imports an external ontology into a document: the vocabulary, the class constructors derived from it, and a foaf:primaryTopic of the source.")
public class ImportOntology extends BaseCommand
{

    /** Accepted response media type of the proxied vocabulary and the derived constructors */
    private static final MediaType[] ACCEPT_RDF_XML = { com.atomgraph.core.MediaType.APPLICATION_RDF_XML_TYPE };
    /** Path of the document holding the constructor derivation query, relative to the admin base URI */
    private static final String CONSTRUCT_CONSTRUCTORS_PATH = "queries/construct-constructors/";

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--source", required = true, paramLabel = "SOURCE_URI", description = "URI of the imported ontology")
    private URI source;

    @Option(names = "--graph", required = true, paramLabel = "GRAPH_URI", description = "URI of the document the ontology is imported into")
    private URI graph;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        Model vocabulary = getVocabulary(base, source);
        String query = getConstructorQuery(base);

        // the vocabulary goes into the target first, so the CONSTRUCT has it to read and it stays afterwards
        post(getClient(), graph, vocabulary);
        post(getClient(), graph, construct(base, query, graph));
        post(getClient(), graph, buildAnnotationModel(graph, source));

        print(graph);

        return 0;
    }

    /**
     * Fetches the source ontology through the Linked Data proxy, which converts any Jena-parseable
     * format to RDF/XML.
     *
     * @param base admin application base URI
     * @param source imported ontology URI
     * @return vocabulary model
     */
    protected Model getVocabulary(URI base, URI source)
    {
        URI target = URI.create(base + "?uri=" + URLEncoder.encode(source.toString(), StandardCharsets.UTF_8));

        try (Response response = HttpException.check(target, getClient().get(target, ACCEPT_RDF_XML)))
        {
            return response.readEntity(Model.class);
        }
    }

    /**
     * Reads the text of the constructor derivation query from its own document.
     *
     * @param base admin application base URI
     * @return SPARQL CONSTRUCT query string
     */
    protected String getConstructorQuery(URI base)
    {
        URI queryDoc = URI.create(base + CONSTRUCT_CONSTRUCTORS_PATH);

        try (Response response = HttpException.check(queryDoc, getClient().get(queryDoc, ACCEPT_TURTLE)))
        {
            Resource query = response.readEntity(Model.class).getResource(queryDoc + "#this");
            if (!query.hasProperty(SP.text)) throw new IllegalStateException("Could not load the transformation query from <" + query + ">");

            return query.getRequiredProperty(SP.text).getString();
        }
    }

    /**
     * Runs the CONSTRUCT over the target graph, which now holds the vocabulary, scoping it via the
     * SPARQL Protocol dataset specification.
     *
     * @param base admin application base URI
     * @param query SPARQL CONSTRUCT query string
     * @param graph target document URI
     * @return derived constructor model
     */
    protected Model construct(URI base, String query, URI graph)
    {
        URI endpoint = URI.create(base + "sparql");
        Form form = new Form("query", query).param("default-graph-uri", graph.toString());

        try (Response response = HttpException.check(endpoint, getClient().postForm(endpoint, form, ACCEPT_RDF_XML)))
        {
            return response.readEntity(Model.class);
        }
    }

    /**
     * Builds the arc saying what the document is about. The document is not the ontology, so it takes
     * no owl:Ontology type of its own: the vocabulary stored alongside carries that.
     *
     * @param graph target document URI
     * @param source imported ontology URI
     * @return primary topic model
     */
    public static Model buildAnnotationModel(URI graph, URI source)
    {
        Model model = ModelFactory.createDefaultModel();

        model.createResource(graph.toString()).
            addProperty(FOAF.primaryTopic, model.createResource(source.toString()));

        return model;
    }

}
