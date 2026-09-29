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

import com.atomgraph.linkeddatahub.rdf.vocabulary.LDH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SD;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SPIN;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * Import descriptions - a file plus the transformation that turns it into RDF.
 * <p>
 * Creating one only describes the import; the platform runs it asynchronously once the
 * description lands.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Imports
{

    private Imports() { }

    /**
     * Builds a CSV import description: a CSV file, the delimiter that parses it, and a
     * CONSTRUCT query mapping each row to triples.
     *
     * @param target target document URI
     * @param uri import URI, relative or absolute (optional, blank node when absent)
     * @param title import title
     * @param query URI of the query mapping rows to triples
     * @param file URI of the CSV file
     * @param delimiter CSV delimiter character
     * @param description import description (optional)
     * @return import model
     */
    public static Model csv(URI target, String uri, String title, URI query, URI file, String delimiter, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource csvImport = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.CSVImport).
            addProperty(DCTerms.title, title).
            addProperty(SPIN.query, model.createResource(query.toString())).
            addProperty(LDH.file, model.createResource(file.toString())).
            addProperty(LDH.delimiter, delimiter);
        if (description != null) csvImport.addProperty(DCTerms.description, description);

        return model;
    }

    /**
     * Builds an RDF import description: an RDF file, optionally transformed by a query and
     * optionally loaded into a named graph.
     *
     * @param target target document URI
     * @param uri import URI, relative or absolute (optional, blank node when absent)
     * @param title import title
     * @param file URI of the RDF file
     * @param query URI of the query transforming the parsed graph (optional)
     * @param graph name of the graph the triples load into (optional)
     * @param description import description (optional)
     * @return import model
     */
    public static Model rdf(URI target, String uri, String title, URI file, URI query, URI graph, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource rdfImport = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.RDFImport).
            addProperty(DCTerms.title, title).
            addProperty(LDH.file, model.createResource(file.toString()));
        if (graph != null) rdfImport.addProperty(SD.name, model.createResource(graph.toString()));
        if (query != null) rdfImport.addProperty(SPIN.query, model.createResource(query.toString()));
        if (description != null) rdfImport.addProperty(DCTerms.description, description);

        return model;
    }

}
