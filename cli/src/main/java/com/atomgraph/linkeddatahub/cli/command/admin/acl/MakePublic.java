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
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.sparql.Updates;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;

/**
 * Makes all end-user application documents publicly readable. Mirrors <code>bin/admin/acl/make-public.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "make-public", description = "Makes all end-user application documents publicly readable.")
public class MakePublic extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        URI adminBase = URIRewriter.adminBase(base);
        URI target = URI.create(adminBase + "acl/authorizations/public/");

        HttpException.check(target, getClient().patch(target, Updates.makePublic(base, adminBase))).close();

        return 0;
    }

    @Override
    protected URI getEffectiveProxy()
    {
        // the request targets the admin app, so the proxy origin gets the admin subdomain too
        return getProxyMixin().getProxy() != null ? URIRewriter.adminBase(getProxyMixin().getProxy()) : null;
    }

}
