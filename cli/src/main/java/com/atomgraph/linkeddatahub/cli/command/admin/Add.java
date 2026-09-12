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
import com.atomgraph.linkeddatahub.cli.command.admin.acl.AddAgentToGroup;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddClass;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddConstructor;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddPropertyConstraint;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddRestriction;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddSelect;
import picocli.CommandLine.Command;

/**
 * Command group appending resources to admin documents.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add",
    description = "Appends resources to admin documents.",
    subcommands = { AddClass.class, AddConstructor.class, AddSelect.class, AddPropertyConstraint.class, AddRestriction.class,
        AddOntologyImport.class, AddAgentToGroup.class })
public class Add extends CommandGroup
{
}
