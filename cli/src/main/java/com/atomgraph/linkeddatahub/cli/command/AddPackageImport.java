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

package com.atomgraph.linkeddatahub.cli.command;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.sparql.Updates;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Imports a package into the application by declaring an <code>ldh:import</code> statement in its
 * settings. The declaration is the installation: the package ontology joins the application's
 * imports closure and its stylesheet is composed into the application stylesheet on the next
 * request, with no restart.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-package-import", description = "Imports a package by declaring an ldh:import statement in the application settings.")
public class AddPackageImport extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--package", required = true, paramLabel = "PACKAGE_URI", description = "URI of the imported package")
    private URI packageURI;

    @Override
    public Integer call() throws Exception
    {
        URI target = URI.create(baseMixin.require(getSpec()) + "settings");

        HttpException.check(target, getClient().patch(target, Updates.insertPackageImport(packageURI))).close();

        return 0;
    }

}
