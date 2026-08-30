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

package com.atomgraph.linkeddatahub.cli.command.admin.acl;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.Slugs;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import com.atomgraph.linkeddatahub.cli.vocab.DH;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Creates an agent group. Mirrors <code>bin/admin/acl/create-group.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "create-group", description = "Creates an agent group.")
public class CreateGroup extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--name", required = true, paramLabel = "NAME", description = "Name of the group")
    private String name;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the group (optional)")
    private String description;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the group (optional, blank node if not set)")
    private String uri;

    @Option(names = "--member", required = true, paramLabel = "MEMBER_URI", description = "URI of a group member (repeatable)")
    private List<URI> members;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI doc = URIRewriter.childURI(URI.create(base + "acl/groups/"), slug != null ? slug : Slugs.defaultSlug());

        put(getClient(), doc, buildModel(doc, uri, name, description, members));
        print(doc);

        return 0;
    }

    /**
     * Builds the group document model.
     *
     * @param doc document URI
     * @param uri group URI (optional, blank node if null)
     * @param name group name
     * @param description group description (optional)
     * @param members member agent URIs
     * @return document model
     */
    public static Model buildModel(URI doc, String uri, String name, String description, List<URI> members)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource group = createSubject(model, doc, uri).
            addProperty(RDF.type, FOAF.Group).
            addProperty(FOAF.name, name);
        if (description != null) group.addProperty(DCTerms.description, description);
        members.forEach(member -> group.addProperty(FOAF.member, model.createResource(member.toString())));

        model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(FOAF.primaryTopic, group).
            addProperty(DCTerms.title, name);

        return model;
    }

}
