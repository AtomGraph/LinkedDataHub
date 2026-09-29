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
import com.atomgraph.linkeddatahub.rdf.Acl;
import com.atomgraph.linkeddatahub.rdf.Slugs;
import com.atomgraph.linkeddatahub.rdf.URIs;
import com.atomgraph.linkeddatahub.rdf.vocabulary.ACL;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import org.apache.jena.rdf.model.Resource;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;

/**
 * Creates an ACL authorization. Mirrors <code>bin/admin/acl/create-authorization.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "authorization", description = "Creates an ACL authorization.")
public class CreateAuthorization extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--label", required = true, paramLabel = "LABEL", description = "Label of the authorization")
    private String label;

    @Option(names = "--comment", paramLabel = "COMMENT", description = "Comment of the authorization (optional)")
    private String comment;

    @Option(names = "--slug", paramLabel = "STRING", description = "String that will be used as URI path segment (optional)")
    private String slug;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the authorization (optional, blank node if not set)")
    private String uri;

    @Option(names = "--agent", paramLabel = "AGENT_URI", description = "URI of an authorized agent (repeatable)")
    private List<URI> agents = new ArrayList<>();

    @Option(names = "--agent-class", paramLabel = "AGENT_CLASS_URI", description = "URI of an authorized agent class (repeatable)")
    private List<URI> agentClasses = new ArrayList<>();

    @Option(names = "--agent-group", paramLabel = "AGENT_GROUP_URI", description = "URI of an authorized agent group (repeatable)")
    private List<URI> agentGroups = new ArrayList<>();

    @Option(names = "--to", paramLabel = "TO_URI", description = "URI of an accessed document (repeatable)")
    private List<URI> to = new ArrayList<>();

    @Option(names = "--to-all-in", paramLabel = "CLASS_URI", description = "URI of an accessed document class (repeatable)")
    private List<URI> toAllIn = new ArrayList<>();

    @Option(names = "--append", description = "Grant acl:Append mode")
    private boolean append;

    @Option(names = "--control", description = "Grant acl:Control mode")
    private boolean control;

    @Option(names = "--read", description = "Grant acl:Read mode")
    private boolean read;

    @Option(names = "--write", description = "Grant acl:Write mode")
    private boolean write;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        if (agents.isEmpty() && agentClasses.isEmpty() && agentGroups.isEmpty())
            throw new ParameterException(getSpec().commandLine(), "At least one of '--agent', '--agent-class', '--agent-group' is required");
        if (to.isEmpty() && toAllIn.isEmpty())
            throw new ParameterException(getSpec().commandLine(), "At least one of '--to', '--to-all-in' is required");
        if (!append && !control && !read && !write)
            throw new ParameterException(getSpec().commandLine(), "At least one of '--append', '--control', '--read', '--write' is required");

        URI doc = URIs.childURI(URI.create(base + "acl/authorizations/"), slug != null ? slug : Slugs.defaultSlug());

        List<Resource> modes = new ArrayList<>();
        if (append) modes.add(ACL.Append);
        if (control) modes.add(ACL.Control);
        if (read) modes.add(ACL.Read);
        if (write) modes.add(ACL.Write);

        put(getClient(), doc, Acl.authorization(doc, uri, label, comment, agents, agentClasses, agentGroups, to, toAllIn, modes));
        print(doc);

        return 0;
    }

}
