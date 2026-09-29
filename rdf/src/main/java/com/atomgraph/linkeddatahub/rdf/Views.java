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

package com.atomgraph.linkeddatahub.rdf;

import com.atomgraph.linkeddatahub.rdf.vocabulary.AC;
import com.atomgraph.linkeddatahub.rdf.vocabulary.LDH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SPIN;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * Views: a query plus how its results are shown.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Views
{

    private Views() { }

    /**
     * Builds a view of a query's results.
     *
     * @param target target document URI
     * @param uri view URI, relative or absolute (optional, blank node when absent)
     * @param query URI of the query the view runs
     * @param title view title (optional)
     * @param description view description (optional)
     * @param mode layout mode URI (optional)
     * @return view model
     */
    public static Model view(URI target, String uri, URI query, String title, String description, URI mode)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource view = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.View).
            addProperty(SPIN.query, model.createResource(query.toString()));
        if (title != null) view.addProperty(DCTerms.title, title);
        if (description != null) view.addProperty(DCTerms.description, description);
        if (mode != null) view.addProperty(AC.mode, model.createResource(mode.toString()));

        return model;
    }

    /**
     * Builds a chart of a SELECT query's result set. The category and series variable names
     * pick the result-set columns the chart's axes read.
     *
     * @param target target document URI
     * @param uri chart URI, relative or absolute (optional, blank node when absent)
     * @param title chart title
     * @param query URI of the query the chart runs
     * @param chartType chart type URI
     * @param categoryVarName result-set variable name providing the categories
     * @param seriesVarName result-set variable name providing the series
     * @param description chart description (optional)
     * @return chart model
     */
    public static Model resultSetChart(URI target, String uri, String title, URI query, URI chartType, String categoryVarName, String seriesVarName, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource chart = Subjects.of(model, target, uri).
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
