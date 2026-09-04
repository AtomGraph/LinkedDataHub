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

package com.atomgraph.linkeddatahub.cli.command.admin;

import com.atomgraph.linkeddatahub.cli.CommandGroup;
import com.atomgraph.linkeddatahub.cli.command.admin.acl.CreateAuthorization;
import com.atomgraph.linkeddatahub.cli.command.admin.acl.CreateGroup;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.CreateOntology;
import picocli.CommandLine.Command;

/**
 * Admin document creation command group.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "create",
    description = "Creates documents in the admin application.",
    subcommands = { CreateOntology.class, CreateGroup.class, CreateAuthorization.class })
public class Create extends CommandGroup
{
}
