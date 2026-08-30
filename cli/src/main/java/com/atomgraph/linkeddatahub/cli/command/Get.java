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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Retrieves an RDF description. Mirrors <code>bin/get.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "get", description = "Retrieves RDF description.")
public class Get extends BaseCommand
{

    @Option(names = "--accept", required = true, paramLabel = "MEDIA_TYPE", description = "Requested media type (e.g. text/turtle)")
    private String accept;

    @Option(names = "--head", description = "Requested headers only, no body (HEAD method)")
    private boolean head;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        MediaType[] acceptedTypes = { MediaType.valueOf(accept) };

        if (head)
            try (Response response = HttpException.check(target, getClient().head(target, acceptedTypes)))
            {
                print("HTTP " + response.getStatus() + " " + response.getStatusInfo().getReasonPhrase());
                response.getStringHeaders().forEach((name, values) -> values.forEach(value -> print(name + ": " + value)));
            }
        else
            printBody(HttpException.check(target, getClient().get(target, acceptedTypes)));

        return 0;
    }

}
