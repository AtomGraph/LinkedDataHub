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

import com.atomgraph.linkeddatahub.rdf.vocabulary.DH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.LDH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SP;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SPIN;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;

/**
 * The terms an application ontology is edited in: the ontology document itself, its classes,
 * their restrictions, and the constructors and constraints attached to them.
 * <p>
 * These carry <code>rdfs:label</code>/<code>rdfs:comment</code> rather than
 * <code>dct:title</code>/<code>dct:description</code> - ontology terms are annotated the way
 * RDFS annotates them, not the way documents are described.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Ontologies
{

    private Ontologies() { }

    /**
     * Builds an ontology document.
     *
     * @param doc document URI
     * @param uri ontology URI, relative or absolute (optional, blank node when absent)
     * @param label ontology label, also the document title
     * @param comment ontology comment (optional)
     * @return ontology model
     */
    public static Model ontology(URI doc, String uri, String label, String comment)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource ontology = Subjects.of(model, doc, uri).
            addProperty(RDF.type, OWL.Ontology).
            addProperty(RDFS.label, label);
        if (comment != null) ontology.addProperty(RDFS.comment, comment);

        model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(FOAF.primaryTopic, ontology).
            addProperty(DCTerms.title, label);

        return model;
    }

    /**
     * Builds a class, with its constructor, constraint and superclasses.
     *
     * @param target target ontology document URI
     * @param uri class URI, relative or absolute (optional, blank node when absent)
     * @param label class label
     * @param comment class comment (optional)
     * @param constructor URI of the query constructing instances of the class (optional)
     * @param constraint URI of the class's constraint (optional)
     * @param superClasses URIs of the class's superclasses
     * @return class model
     */
    public static Model owlClass(URI target, String uri, String label, String comment, URI constructor, URI constraint, List<URI> superClasses)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource cls = Subjects.of(model, target, uri).
            addProperty(RDF.type, OWL.Class).
            addProperty(RDFS.label, label);
        if (comment != null) cls.addProperty(RDFS.comment, comment);
        if (constructor != null) cls.addProperty(SPIN.constructor, model.createResource(constructor.toString()));
        if (constraint != null) cls.addProperty(SPIN.constraint, model.createResource(constraint.toString()));
        superClasses.forEach(superClass -> cls.addProperty(RDFS.subClassOf, model.createResource(superClass.toString())));

        return model;
    }

    /**
     * Builds a property restriction.
     *
     * @param target target ontology document URI
     * @param uri restriction URI, relative or absolute (optional, blank node when absent)
     * @param label restriction label
     * @param comment restriction comment (optional)
     * @param onProperty URI of the restricted property (optional)
     * @param allValuesFrom URI of the class the property's values must come from (optional)
     * @param hasValue URI of the value the property must have (optional)
     * @return restriction model
     */
    public static Model restriction(URI target, String uri, String label, String comment, URI onProperty, URI allValuesFrom, URI hasValue)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource restriction = Subjects.of(model, target, uri).
            addProperty(RDF.type, OWL.Restriction).
            addProperty(RDFS.label, label);
        if (comment != null) restriction.addProperty(RDFS.comment, comment);
        if (onProperty != null) restriction.addProperty(OWL.onProperty, model.createResource(onProperty.toString()));
        if (allValuesFrom != null) restriction.addProperty(OWL.allValuesFrom, model.createResource(allValuesFrom.toString()));
        if (hasValue != null) restriction.addProperty(OWL.hasValue, model.createResource(hasValue.toString()));

        return model;
    }

    /**
     * Builds a SPIN constructor query - the query that builds a new instance of a class.
     * <p>
     * The same shape as {@link Queries#query}, annotated for an ontology rather than described
     * as a document.
     *
     * @param target target ontology document URI
     * @param uri query URI, relative or absolute (optional, blank node when absent)
     * @param queryType query form, e.g. {@link SP#Construct}
     * @param label query label
     * @param queryText the SPARQL query string
     * @param service URI of the SPARQL service the query runs against (optional)
     * @param comment query comment (optional)
     * @return constructor model
     */
    public static Model constructor(URI target, String uri, Resource queryType, String label, String queryText, URI service, String comment)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource query = Subjects.of(model, target, uri).
            addProperty(RDF.type, queryType).
            addProperty(RDFS.label, label).
            addProperty(SP.text, queryText);
        if (comment != null) query.addProperty(RDFS.comment, comment);
        if (service != null) query.addProperty(LDH.service, model.createResource(service.toString()));

        return model;
    }

    /**
     * Builds a constraint requiring a property to have a value.
     *
     * @param target target ontology document URI
     * @param uri constraint URI, relative or absolute (optional, blank node when absent)
     * @param label constraint label
     * @param property URI of the property that must have a value
     * @param comment constraint comment (optional)
     * @return constraint model
     */
    public static Model propertyConstraint(URI target, String uri, String label, URI property, String comment)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource constraint = Subjects.of(model, target, uri).
            addProperty(RDF.type, LDH.MissingPropertyValue).
            addProperty(RDFS.label, label).
            addProperty(SP.arg1, model.createResource(property.toString()));
        if (comment != null) constraint.addProperty(RDFS.comment, comment);

        return model;
    }

    /**
     * Builds the annotation naming an imported ontology's source, written into the graph the
     * import landed in.
     *
     * @param graph URI of the graph the ontology was imported into
     * @param source URI the ontology was imported from
     * @return annotation model
     */
    public static Model annotation(URI graph, URI source)
    {
        Model model = ModelFactory.createDefaultModel();

        model.createResource(graph.toString()).
            addProperty(FOAF.primaryTopic, model.createResource(source.toString()));

        return model;
    }

}
