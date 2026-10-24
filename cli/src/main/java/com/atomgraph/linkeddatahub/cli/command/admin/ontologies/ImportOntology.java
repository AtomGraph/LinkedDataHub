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
import com.atomgraph.linkeddatahub.rdf.Ontologies;
import com.atomgraph.linkeddatahub.rdf.vocabulary.LDS;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SP;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import picocli.CommandLine.ArgGroup;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;

/**
 * Imports an ontology into a document, either an external one by URI or a local file.
 * <p>
 * With <code>--source</code>, imports an external ontology: the vocabulary itself, the class constructors derived
 * from it, and a <code>foaf:primaryTopic</code> naming what the document is about. The vocabulary is fetched through the Linked Data proxy and
 * stays in the target, which is what makes the import an import: the graph carries the vocabulary's own header, so
 * resolving its URI finds this document with the derived annotations on it. The document remains a
 * <code>dh:Item</code> and never claims to be the ontology. The same shape the browser's import produces, and the one
 * a materialized package ontology has.
 * <p>
 * With <code>--file</code>, installs a local file as the dataspace's namespace ontology: the end-user base's
 * <code>lds:ontology</code> link names the ontology, the file is parsed against it, and the namespace document is
 * replaced, keeping its own description and its ontology header (with the <code>owl:imports</code> of the platform's
 * ontology), so that a re-run converges and a term removed from the file is gone. The cached ontology is then cleared.
 * No constructors are derived: the file declares its own.
 * <p>
 * The base URI is the dataspace's. <code>--source</code> accepts the end-user or the admin base; <code>--file</code>
 * needs the end-user one, which links both the ontology and the admin application.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "ontology", description = "Imports an ontology into a document: an external one (--source) with the class constructors derived from it, or a local file (--file) as the dataspace's namespace ontology.")
public class ImportOntology extends BaseCommand
{

    private static final MediaType[] ACCEPT_RDF_XML = { com.atomgraph.core.MediaType.APPLICATION_RDF_XML_TYPE };
    private static final String CONSTRUCT_CONSTRUCTORS_PATH = "queries/construct-constructors/";
    /** Path of the namespace ontology document, relative to the admin base: the slug the platform seeds */
    private static final String NAMESPACE_DOCUMENT_PATH = "ontologies/namespace/";

    @Mixin
    private BaseMixin baseMixin;

    @ArgGroup(exclusive = true, multiplicity = "1")
    private Input input;

    @Option(names = "--graph", paramLabel = "GRAPH_URI", description = "URI of the document the ontology is imported into (required with --source; default with --file: the namespace ontology document)")
    private URI graph;

    @Option(names = { "-t", "--content-type" }, paramLabel = "MEDIA_TYPE", description = "Media type of the --file (default: from the file extension; required for stdin)")
    private String contentType;

    /** What is imported: an external ontology or a local file. */
    static class Input
    {

        @Option(names = "--source", required = true, paramLabel = "SOURCE_URI", description = "URI of the imported external ontology")
        private URI source;

        @Option(names = "--file", required = true, paramLabel = "PATH", description = "Path to a local ontology file to install as the namespace ontology ('-' reads stdin)")
        private String file;

    }

    @Override
    public Integer call() throws Exception
    {
        if (input.source != null) return importSource(baseMixin.require(getSpec()));

        return importFile(baseMixin.require(getSpec()));
    }

    /**
     * Imports an external ontology with its derived constructors.
     *
     * @param base dataspace base URI
     * @return exit code
     */
    protected Integer importSource(URI base)
    {
        if (graph == null) throw new ParameterException(getSpec().commandLine(), "Missing required option: '--graph=GRAPH_URI' (required with --source)");

        URI adminBase = getAdminBase(base);
        Model vocabulary = getVocabulary(adminBase, input.source);
        String query = getConstructorQuery(adminBase);

        // the vocabulary goes into the target first, so the CONSTRUCT has it to read and it stays afterwards
        post(getClient(), graph, vocabulary);
        post(getClient(), graph, construct(adminBase, query, graph));
        post(getClient(), graph, Ontologies.annotation(graph, input.source));

        print(graph);

        return 0;
    }

    /**
     * Installs a local file as the dataspace's namespace ontology.
     *
     * @param base end-user dataspace base URI
     * @return exit code
     * @throws java.io.IOException if the file cannot be read
     */
    protected Integer importFile(URI base) throws java.io.IOException
    {
        Path path = input.file.equals("-") ? null : Path.of(input.file);
        String mediaType = resolveContentType(contentType, path);

        URI adminBase = getAdminBase(base);
        if (adminBase.equals(base)) throw new ParameterException(getSpec().commandLine(), "<" + base + "> is the admin base URI: --file needs the end-user base URI");
        List<URI> ontologies = getLinkTargets(base, LDS.ontology.getURI());
        if (ontologies.isEmpty()) throw new IllegalStateException("<" + base + "> advertises no lds:ontology link");
        URI ontology = ontologies.get(0);
        URI doc = graph != null ? graph : adminBase.resolve(NAMESPACE_DOCUMENT_PATH);

        // parsed against the ontology IRI, so that <#> in the file is the ontology itself (RFC 3986 drops the base's fragment)
        Model file = path != null ? readModel(mediaType, ontology, path) : readModel(mediaType, ontology, System.in);

        Model current;
        try (Response response = HttpException.check(doc, getClient().get(doc, ACCEPT_TURTLE)))
        {
            current = response.readEntity(Model.class);
        }

        put(getClient(), doc, file.add(header(current, current.createResource(doc.toString()))));
        clear(adminBase, ontology);

        print(doc);

        return 0;
    }

    /**
     * Returns the statements of a document that a re-install keeps: those about the document itself and about its
     * primary topics, the ontology header the platform seeds. The same statements <code>patch-ontology.ru</code> kept.
     *
     * @param model document model
     * @param doc document resource
     * @return header statements
     */
    public static Model header(Model model, Resource doc)
    {
        Model header = ModelFactory.createDefaultModel();
        header.add(model.listStatements(doc, null, (RDFNode)null));
        model.listObjectsOfProperty(doc, FOAF.primaryTopic).filterKeep(RDFNode::isResource).
            forEach(topic -> header.add(model.listStatements(topic.asResource(), null, (RDFNode)null)));

        return header;
    }

    /**
     * Clears an ontology from the admin application's cache, reloading it.
     *
     * @param adminBase admin application base URI
     * @param ontology ontology URI
     */
    protected void clear(URI adminBase, URI ontology)
    {
        URI target = URI.create(adminBase + "clear");

        HttpException.checkWrite(target, getClient().postForm(target, new Form("uri", ontology.toString()), ACCEPT_TURTLE)).close();
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

}
