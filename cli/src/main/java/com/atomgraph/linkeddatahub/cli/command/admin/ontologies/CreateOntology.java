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
import com.atomgraph.linkeddatahub.rdf.Slugs;
import com.atomgraph.linkeddatahub.rdf.URIs;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Creates a new ontology document. Mirrors <code>bin/admin/ontologies/create-ontology.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "ontology", description = "Creates a new ontology.")
public class CreateOntology extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the ontology")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the ontology (optional)")
    private String comment;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the ontology (optional, blank node if not set)")
    private String uri;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI doc = URIs.childURI(URI.create(base + "ontologies/"), slug != null ? slug : Slugs.defaultSlug());

        put(getClient(), doc, Ontologies.ontology(doc, uri, label, comment));
        print(doc);

        return 0;
    }

}
