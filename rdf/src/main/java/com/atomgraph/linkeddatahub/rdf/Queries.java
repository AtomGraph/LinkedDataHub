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
import com.atomgraph.linkeddatahub.rdf.vocabulary.SP;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * Stored SPARQL queries.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Queries
{

    private Queries() { }

    /**
     * Builds a stored query. The query form is the caller's to state - {@link SP#Select},
     * {@link SP#Construct} and {@link SP#Describe} are all stored the same way, and only the
     * type says which one this is.
     *
     * @param target target document URI
     * @param uri query URI, relative or absolute (optional, blank node when absent)
     * @param queryType query form, e.g. {@link SP#Select}
     * @param title query title
     * @param queryText the SPARQL query string
     * @param service URI of the SPARQL service the query runs against (optional)
     * @param description query description (optional)
     * @return query model
     */
    public static Model query(URI target, String uri, Resource queryType, String title, String queryText, URI service, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource query = Subjects.of(model, target, uri).
            addProperty(RDF.type, queryType).
            addProperty(DCTerms.title, title).
            addProperty(SP.text, queryText);
        if (service != null) query.addProperty(LDH.service, model.createResource(service.toString()));
        if (description != null) query.addProperty(DCTerms.description, description);

        return model;
    }

}
