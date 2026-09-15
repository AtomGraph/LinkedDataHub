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
import java.nio.file.Path;
import org.apache.jena.rdf.model.Model;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Creates an RDF document from a file or standard input. Mirrors <code>bin/post.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "post", description = "Creates an RDF document from a file or stdin.")
public class Post extends BaseCommand
{

    @Option(names = {"-t", "--content-type"}, paramLabel = "MEDIA_TYPE", description = "Media type of the RDF body (e.g. text/turtle); implied by FILE's extension when absent, required with stdin")
    private String contentType;

    @Parameters(index = "0", paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Parameters(index = "1", arity = "0..1", paramLabel = "FILE", description = "Path to the RDF file (stdin is read when absent)")
    private Path file;

    @Override
    public Integer call() throws Exception
    {
        String mediaType = resolveContentType(contentType, file);
        Model model = file != null ? readModel(mediaType, target, file) : readModel(mediaType, target, System.in);
        HttpException.check(target, getClient().post(target, Entity.entity(model, MediaType.valueOf(mediaType)), ACCEPT_TURTLE)).close();
        print(target);

        return 0;
    }

}
