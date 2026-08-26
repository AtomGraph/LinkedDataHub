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
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.sparql.Updates;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Adds an agent to a group. Mirrors <code>bin/admin/acl/add-agent-to-group.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-agent-to-group", description = "Adds an agent to a group.")
public class AddAgentToGroup extends BaseCommand
{

    @Option(names = "--agent", required = true, paramLabel = "AGENT_URI", description = "URI of the agent")
    private URI agent;

    @Parameters(paramLabel = "GROUP_DOC_URI", description = "URI of the group document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        HttpException.check(target, getClient().patch(target, Updates.insertGroupMember(target, agent))).close();

        return 0;
    }

}
