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
import com.atomgraph.linkeddatahub.rdf.vocabulary.DH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.LDH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SPIN;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * The two document kinds of the hierarchy: containers and items.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Documents
{

    private Documents() { }

    /**
     * Builds the container document model with its first content block: the given block URI,
     * a children view with an explicit mode, or the default children view.
     *
     * @param doc document URI
     * @param title document title
     * @param description document description (optional)
     * @param block content block URI (optional)
     * @param mode children view mode URI (optional, ignored when block is given)
     * @param primaryTopic URI of the document's primary topic, relative or absolute (optional)
     * @return document model
     */
    public static Model container(URI doc, String title, String description, URI block, URI mode, String primaryTopic)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource container = model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Container).
            addProperty(DCTerms.title, title);

        if (block != null) container.addProperty(RDF.li(1), model.createResource(block.toString()));
        else if (mode != null) container.addProperty(RDF.li(1), model.createResource().
                addProperty(RDF.type, LDH.Object).
                addProperty(RDF.value, model.createResource().
                    addProperty(RDF.type, LDH.View).
                    addProperty(SPIN.query, LDH.SelectChildren).
                    addProperty(AC.mode, model.createResource(mode.toString()))));
        else container.addProperty(RDF.li(1), model.createResource().
                addProperty(RDF.type, LDH.Object).
                addProperty(RDF.value, LDH.ChildrenView));

        if (description != null) container.addProperty(DCTerms.description, description);
        // See item(): resolved against the document, and singular by the vocabulary.
        if (primaryTopic != null) container.addProperty(FOAF.primaryTopic, model.createResource(doc.resolve(primaryTopic).toString()));

        return model;
    }

    /**
     * Builds the item document model.
     *
     * @param doc document URI
     * @param title document title
     * @param description document description (optional)
     * @param primaryTopic URI of the document's primary topic, relative or absolute (optional)
     * @return document model
     */
    public static Model item(URI doc, String title, String description, String primaryTopic)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource item = model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(DCTerms.title, title);
        if (description != null) item.addProperty(DCTerms.description, description);
        // Resolved against the document, so the conventional fragment topic is "#this" and a
        // document about something described elsewhere takes that resource's absolute URI.
        // Singular because foaf:primaryTopic is an owl:FunctionalProperty: a second value would
        // not mean a second topic, it would entail the two topics are the same resource.
        if (primaryTopic != null) item.addProperty(FOAF.primaryTopic, model.createResource(doc.resolve(primaryTopic).toString()));

        return model;
    }

}
