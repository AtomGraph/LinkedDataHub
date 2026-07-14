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
import com.atomgraph.linkeddatahub.cli.vocab.SD;
import com.atomgraph.linkeddatahub.cli.vocab.SPIN;
import jakarta.ws.rs.client.Entity;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.DCTerms;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Imports an external ontology into a named graph via the transform endpoint.
 * Mirrors <code>bin/admin/ontologies/import-ontology.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "import-ontology", description = "Imports an external ontology into a named graph.")
public class ImportOntology extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--source", required = true, paramLabel = "SOURCE_URI", description = "URI of the imported ontology")
    private URI source;

    @Option(names = "--graph", required = true, paramLabel = "GRAPH_URI", description = "URI of the named graph the ontology is imported into")
    private URI graph;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI target = URI.create(base + "transform");

        printBody(HttpException.check(target, getClient().post(target, Entity.entity(buildModel(base, source, graph), TEXT_TURTLE_TYPE), ACCEPT_TURTLE)));

        return 0;
    }

    /**
     * Builds the transform argument description.
     *
     * @param base admin application base URI
     * @param source imported ontology URI
     * @param graph target named graph URI
     * @return argument model
     */
    public static Model buildModel(URI base, URI source, URI graph)
    {
        Model model = ModelFactory.createDefaultModel();

        model.createResource().
            addProperty(DCTerms.source, model.createResource(source.toString())).
            addProperty(SD.name, model.createResource(graph.toString())).
            addProperty(SPIN.query, model.createResource(base + "queries/construct-constructors/#this"));

        return model;
    }

}
