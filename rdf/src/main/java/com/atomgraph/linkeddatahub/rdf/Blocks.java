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
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * Content blocks, the ordered body of a document.
 * <p>
 * A block is attached to its document by a container membership property
 * (<code>rdf:_1</code>, <code>rdf:_2</code>, …) which fixes its position; see
 * {@link SequenceNumbers} for reading the next free one off an existing document.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Blocks
{

    private Blocks() { }

    /**
     * Builds an object block: a block whose value is another resource, rendered by the mode given.
     *
     * @param target target document URI
     * @param seq container membership property fixing the block's position
     * @param uri block URI, relative or absolute (optional, blank node when absent)
     * @param value URI of the resource the block shows
     * @param title block title (optional)
     * @param description block description (optional)
     * @param mode layout mode URI (optional)
     * @return block model
     */
    public static Model object(URI target, Property seq, String uri, URI value, String title, String description, URI mode)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource block = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.Object).
            addProperty(RDF.value, model.createResource(value.toString()));
        model.createResource(target.toString()).addProperty(seq, block);
        if (title != null) block.addProperty(DCTerms.title, title);
        if (description != null) block.addProperty(DCTerms.description, description);
        if (mode != null) block.addProperty(AC.mode, model.createResource(mode.toString()));

        return model;
    }

    /**
     * Builds an XHTML block: a block whose value is markup carried as an
     * <code>rdf:XMLLiteral</code>.
     *
     * @param target target document URI
     * @param seq container membership property fixing the block's position
     * @param uri block URI, relative or absolute (optional, blank node when absent)
     * @param value XHTML markup
     * @param title block title (optional)
     * @param description block description (optional)
     * @return block model
     */
    public static Model xhtml(URI target, Property seq, String uri, String value, String title, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource block = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.XHTML).
            addProperty(RDF.value, model.createTypedLiteral(value, RDF.dtXMLLiteral));
        model.createResource(target.toString()).addProperty(seq, block);
        if (title != null) block.addProperty(DCTerms.title, title);
        if (description != null) block.addProperty(DCTerms.description, description);

        return model;
    }

}
