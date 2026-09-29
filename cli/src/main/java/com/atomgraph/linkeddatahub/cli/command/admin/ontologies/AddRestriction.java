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
import com.atomgraph.linkeddatahub.rdf.Ontologies;
import java.net.URI;
import org.apache.jena.vocabulary.OWL;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds an OWL restriction to an ontology. Mirrors <code>bin/admin/ontologies/add-restriction.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "restriction", description = "Adds an OWL restriction to an ontology.")
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

        post(getClient(), target, Ontologies.restriction(target, uri, label, comment, onProperty, allValuesFrom, hasValue));
        print(target);

        return 0;
    }

}
