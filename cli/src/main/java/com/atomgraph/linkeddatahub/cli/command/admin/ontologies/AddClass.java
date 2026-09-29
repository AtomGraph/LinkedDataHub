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
import java.util.ArrayList;
import java.util.List;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds a class to an ontology. Mirrors <code>bin/admin/ontologies/add-class.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "class", description = "Adds a class to an ontology.")
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

        post(getClient(), target, Ontologies.owlClass(target, uri, label, comment, constructor, constraint, superClasses));
        print(target);

        return 0;
    }

}
