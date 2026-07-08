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

package com.atomgraph.linkeddatahub.cli.command.admin.packages;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import jakarta.ws.rs.core.Form;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Uninstalls a LinkedDataHub package. Mirrors <code>bin/admin/packages/uninstall-package.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "uninstall-package", description = "Uninstalls a package.")
public class UninstallPackage extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--package", required = true, paramLabel = "PACKAGE_URI", description = "URI of the package")
    private URI packageURI;

    @Override
    public Integer call() throws Exception
    {
        URI target = URI.create(URIRewriter.adminBase(baseMixin.require(getSpec())) + "packages/uninstall");
        HttpException.check(target, getClient().postForm(target, new Form("package-uri", packageURI.toString()), ACCEPT_TURTLE)).close();

        return 0;
    }

    @Override
    protected URI getEffectiveProxy()
    {
        // the request targets the admin app, so the proxy origin gets the admin subdomain too
        return getProxyMixin().getProxy() != null ? URIRewriter.adminBase(getProxyMixin().getProxy()) : null;
    }

}
