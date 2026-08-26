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

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import jakarta.ws.rs.core.Form;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Clears an ontology from memory so it gets reloaded. Mirrors <code>bin/admin/clear-ontology.sh</code>.
 * The base URI is the base of the <em>admin</em> application.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "clear-ontology", description = "Clears an ontology from memory and reloads it.")
public class ClearOntology extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--ontology", required = true, paramLabel = "ONTOLOGY_URI", description = "URI of the ontology")
    private URI ontology;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI target = URI.create(base + "clear");

        printBody(HttpException.check(target, getClient().postForm(target, new Form("uri", ontology.toString()), ACCEPT_TURTLE)));

        return 0;
    }

}
