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
 * Appends a chart of SPARQL SELECT results to a document. Mirrors <code>bin/add-result-set-chart.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-result-set-chart", description = "Appends a result set chart to a document.")
public class AddResultSetChart extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the chart")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the chart (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the chart (optional, blank node if not set)")
    private String uri;

    @Option(names = "--query", required = true, paramLabel = "QUERY_URI", description = "URI of the SELECT query")
    private URI query;

    @Option(names = "--chart-type", required = true, paramLabel = "TYPE_URI", description = "URI of the chart type")
    private URI chartType;

    @Option(names = "--category-var-name", required = true, paramLabel = "VAR_NAME", description = "Name of the category variable")
    private String categoryVarName;

    @Option(names = "--series-var-name", required = true, paramLabel = "VAR_NAME", description = "Name of the series variable")
    private String seriesVarName;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, buildModel(target, uri, title, query, chartType, categoryVarName, seriesVarName, description));
        print(target);

        return 0;
    }

    /**
     * Builds the chart description.
     *
     * @param target target document URI
     * @param uri chart URI (optional)
     * @param title chart title
     * @param query SELECT query URI
     * @param chartType chart type URI
     * @param categoryVarName category variable name
     * @param seriesVarName series variable name
     * @param description chart description (optional)
     * @return chart model
     */
    public static Model buildModel(URI target, String uri, String title, URI query, URI chartType, String categoryVarName, String seriesVarName, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource chart = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.ResultSetChart).
            addProperty(DCTerms.title, title).
            addProperty(SPIN.query, model.createResource(query.toString())).
            addProperty(LDH.chartType, model.createResource(chartType.toString())).
            addProperty(LDH.categoryVarName, categoryVarName).
            addProperty(LDH.seriesVarName, seriesVarName);
        if (description != null) chart.addProperty(DCTerms.description, description);

        return model;
    }

}
