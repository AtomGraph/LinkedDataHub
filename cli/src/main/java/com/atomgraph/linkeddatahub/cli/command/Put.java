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
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Creates or updates an RDF document from standard input. Mirrors <code>bin/put.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "put", description = "Creates or updates an RDF document from stdin.")
public class Put extends BaseCommand
{

    @Option(names = {"-t", "--content-type"}, required = true, paramLabel = "MEDIA_TYPE", description = "Media type of the RDF body (e.g. text/turtle)")
    private String contentType;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        Model model = readModel(contentType, target, System.in);
        HttpException.check(target, getClient().put(target, Entity.entity(model, MediaType.valueOf(contentType)), ACCEPT_TURTLE)).close();
        print(target);

        return 0;
    }

}
