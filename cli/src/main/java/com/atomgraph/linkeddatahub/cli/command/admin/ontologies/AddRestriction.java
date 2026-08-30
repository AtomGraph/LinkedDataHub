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
import java.net.URI;
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
 * Adds an OWL restriction to an ontology. Mirrors <code>bin/admin/ontologies/add-restriction.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-restriction", description = "Adds an OWL restriction to an ontology.")
public class AddRestriction extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the restriction")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the restriction (optional)")
    private String comment;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the restriction (optional, blank node if not set)")
    private String uri;

    @Option(names = "--on-property", paramLabel = "PROPERTY_URI", description = "URI of the restricted property (optional)")
    private URI onProperty;

    @Option(names = "--all-values-from", paramLabel = "URI", description = "URI of the value class (optional)")
    private URI allValuesFrom;

    @Option(names = "--has-value", paramLabel = "URI", description = "URI of the value resource (optional)")
    private URI hasValue;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the ontology document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, buildModel(target, uri, label, comment, onProperty, allValuesFrom, hasValue));
        print(target);

        return 0;
    }

    /**
     * Builds the restriction description.
     *
     * @param target target document URI
     * @param uri restriction URI (optional)
     * @param label restriction label
     * @param comment restriction comment (optional)
     * @param onProperty restricted property URI (optional)
     * @param allValuesFrom value class URI (optional)
     * @param hasValue value resource URI (optional)
     * @return restriction model
     */
    public static Model buildModel(URI target, String uri, String label, String comment, URI onProperty, URI allValuesFrom, URI hasValue)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource restriction = createSubject(model, target, uri).
            addProperty(RDF.type, OWL.Restriction).
            addProperty(RDFS.label, label);
        if (comment != null) restriction.addProperty(RDFS.comment, comment);
        if (onProperty != null) restriction.addProperty(OWL.onProperty, model.createResource(onProperty.toString()));
        if (allValuesFrom != null) restriction.addProperty(OWL.allValuesFrom, model.createResource(allValuesFrom.toString()));
        if (hasValue != null) restriction.addProperty(OWL.hasValue, model.createResource(hasValue.toString()));

        return model;
    }

}
