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
import com.atomgraph.linkeddatahub.cli.vocab.DH;
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Imports an external ontology: derives class constructors from its triples and appends them,
 * together with an <code>owl:imports</code> of the source, to a document.
 * Mirrors <code>bin/admin/ontologies/import-ontology.sh</code>.
 *
 * The vocabulary itself is scaffolding: it is fetched through the Linked Data proxy into a scratch
 * document that scopes the <code>construct-constructors</code> CONSTRUCT via the SPARQL Protocol
 * dataset specification, then deleted - on the error paths too. Only the derived annotations
 * persist; the vocabulary resolves live through the graph repository.
 *
 * The base URI is the base of the <em>admin</em> application.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "import-ontology", description = "Derives class constructors from an external ontology and appends them, with an owl:imports of the source, to a document.")
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
        URI scratch = URI.create(base + UUID.randomUUID().toString() + "/");

        put(getClient(), scratch, buildScratchModel(scratch));

        try
        {
            post(getClient(), scratch, vocabulary);
            post(getClient(), graph, construct(base, query, scratch));
            post(getClient(), graph, buildAnnotationModel(graph, source));
        }
        finally
        {
            deleteScratch(scratch);
        }

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
     * Runs the CONSTRUCT over the scratch graph, scoping it via the SPARQL Protocol dataset specification.
     *
     * @param base admin application base URI
     * @param query SPARQL CONSTRUCT query string
     * @param scratch scratch document URI
     * @return derived constructor model
     */
    protected Model construct(URI base, String query, URI scratch)
    {
        URI endpoint = URI.create(base + "sparql");
        Form form = new Form("query", query).param("default-graph-uri", scratch.toString());

        try (Response response = HttpException.check(endpoint, getClient().postForm(endpoint, form, ACCEPT_RDF_XML)))
        {
            return response.readEntity(Model.class);
        }
    }

    /**
     * Deletes the scratch document, best-effort: a failure here is reported but never masks the
     * outcome of the derivation itself.
     *
     * @param scratch scratch document URI
     */
    protected void deleteScratch(URI scratch)
    {
        try
        {
            getClient().delete(scratch).close();
        }
        catch (Exception e)
        {
            getSpec().commandLine().getErr().println("Could not delete the scratch document <" + scratch + ">: " + e.getMessage());
        }
    }

    /**
     * Builds the description of the scratch document that holds the vocabulary during the derivation.
     *
     * @param scratch scratch document URI
     * @return scratch document model
     */
    public static Model buildScratchModel(URI scratch)
    {
        Model model = ModelFactory.createDefaultModel();

        model.createResource(scratch.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(DCTerms.title, "Import ontology scratch");

        return model;
    }

    /**
     * Builds the annotation ontology header: the document imports the source vocabulary, which
     * resolves live through the graph repository.
     *
     * @param graph target document URI
     * @param source imported ontology URI
     * @return annotation header model
     */
    public static Model buildAnnotationModel(URI graph, URI source)
    {
        Model model = ModelFactory.createDefaultModel();

        model.createResource(graph.toString()).
            addProperty(RDF.type, OWL.Ontology).
            addProperty(OWL.imports, model.createResource(source.toString()));

        return model;
    }

}
