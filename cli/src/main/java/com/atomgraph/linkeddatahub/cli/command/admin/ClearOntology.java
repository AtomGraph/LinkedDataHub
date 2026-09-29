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
 * Clears the application's cached graphs and assembled imports closures from memory.
 * Mirrors <code>bin/admin/clear-ontology.sh</code>.
 *
 * With <code>--ontology</code> the named ontology is also reloaded before the response returns, so the
 * next request already reads the new version. Without it nothing is reloaded and the closures rebuild
 * lazily, which is what a caller wanting only a cold cache should ask for.
 *
 * The base URI is the base of the <em>admin</em> application.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "ontology", description = "Clears cached graphs and imports closures from memory, reloading the named ontology if one is given.")
public class ClearOntology extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--ontology", paramLabel = "ONTOLOGY_URI", description = "URI of the ontology to reload after clearing; without it nothing is reloaded")
    private URI ontology;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI target = URI.create(base + "clear");
        Form form = ontology != null ? new Form("uri", ontology.toString()) : new Form();

        printBody(HttpException.check(target, getClient().postForm(target, form, ACCEPT_TURTLE)));

        return 0;
    }

}
