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
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds a constraint that makes a property required. Mirrors <code>bin/admin/ontologies/add-property-constraint.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-property-constraint", description = "Adds a constraint that makes a property required.")
public class AddPropertyConstraint extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the constraint")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the constraint (optional)")
    private String comment;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the constraint (optional, blank node if not set)")
    private String uri;

    @Option(names = "--property", required = true, paramLabel = "PROPERTY_URI", description = "URI of the required property")
    private URI property;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the ontology document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, buildModel(target, uri, label, property, comment));
        print(target);

        return 0;
    }

    /**
     * Builds the constraint description.
     *
     * @param target target document URI
     * @param uri constraint URI (optional)
     * @param label constraint label
     * @param property required property URI
     * @param comment constraint comment (optional)
     * @return constraint model
     */
    public static Model buildModel(URI target, String uri, String label, URI property, String comment)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource constraint = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.MissingPropertyValue).
            addProperty(RDFS.label, label).
            addProperty(SP.arg1, model.createResource(property.toString()));
        if (comment != null) constraint.addProperty(RDFS.comment, comment);

        return model;
    }

}
