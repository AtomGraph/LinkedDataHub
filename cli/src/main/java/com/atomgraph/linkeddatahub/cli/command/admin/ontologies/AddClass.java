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
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.vocab.SPIN;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds a class to an ontology. Mirrors <code>bin/admin/ontologies/add-class.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-class", description = "Adds a class to an ontology.")
public class AddClass extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the class")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the class (optional)")
    private String comment;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the class (optional, blank node if not set)")
    private String uri;

    @Option(names = "--constructor", paramLabel = "CONSTRUCT_URI", description = "URI of the constructor query (optional)")
    private URI constructor;

    @Option(names = "--constraint", paramLabel = "CONSTRAINT_URI", description = "URI of the constraint (optional)")
    private URI constraint;

    @Option(names = "--sub-class-of", paramLabel = "SUPER_CLASS_URI", description = "URI of a superclass (optional, repeatable)")
    private List<URI> superClasses = new ArrayList<>();

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the ontology document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, buildModel(target, uri, label, comment, constructor, constraint, superClasses));
        print(target);

        return 0;
    }

    /**
     * Builds the class description.
     *
     * @param target target document URI
     * @param uri class URI (optional)
     * @param label class label
     * @param comment class comment (optional)
     * @param constructor constructor query URI (optional)
     * @param constraint constraint URI (optional)
     * @param superClasses superclass URIs
     * @return class model
     */
    public static Model buildModel(URI target, String uri, String label, String comment, URI constructor, URI constraint, List<URI> superClasses)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource cls = createSubject(model, target, uri).
            addProperty(RDF.type, OWL.Class).
            addProperty(RDFS.label, label);
        if (comment != null) cls.addProperty(RDFS.comment, comment);
        if (constructor != null) cls.addProperty(SPIN.constructor, model.createResource(constructor.toString()));
        if (constraint != null) cls.addProperty(SPIN.constraint, model.createResource(constraint.toString()));
        superClasses.forEach(superClass -> cls.addProperty(RDFS.subClassOf, model.createResource(superClass.toString())));

        return model;
    }

}
