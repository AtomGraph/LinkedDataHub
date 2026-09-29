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
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.rdf.Services;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Appends a generic SPARQL service description to a document. Mirrors <code>bin/add-generic-service.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "generic-service", description = "Appends a generic SPARQL service to a document.")
public class AddGenericService extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the service")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the service (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the service (optional, blank node if not set)")
    private String uri;

    @Option(names = "--endpoint", required = true, paramLabel = "ENDPOINT_URI", description = "URI of the SPARQL endpoint")
    private URI endpoint;

    @Option(names = "--graph-store", paramLabel = "GRAPH_STORE_URI", description = "URI of the Graph Store Protocol endpoint (optional)")
    private URI graphStore;

    @Option(names = "--auth-user", paramLabel = "AUTH_USER", description = "Username for HTTP Basic auth (optional)")
    private String authUser;

    @Option(names = "--auth-pwd", paramLabel = "AUTH_PASSWORD", description = "Password for HTTP Basic auth (optional)")
    private String authPwd;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        baseMixin.require(getSpec()); // required by the script interface

        post(getClient(), target, Services.service(target, uri, title, endpoint, graphStore, authUser, authPwd, description));
        print(target);

        return 0;
    }

}
