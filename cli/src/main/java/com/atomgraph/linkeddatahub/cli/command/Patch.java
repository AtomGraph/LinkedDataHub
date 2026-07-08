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
import java.net.URI;
import java.nio.charset.StandardCharsets;
import org.apache.jena.query.Syntax;
import org.apache.jena.update.UpdateFactory;
import picocli.CommandLine.Command;
import picocli.CommandLine.Parameters;

/**
 * Patches an RDF document with a SPARQL update from standard input. Mirrors <code>bin/patch.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "patch", description = "Patches an RDF document using SPARQL update from stdin.")
public class Patch extends BaseCommand
{

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        String update = new String(System.in.readAllBytes(), StandardCharsets.UTF_8);
        // validate as standard SPARQL 1.1 before sending; the original text is sent unmodified
        UpdateFactory.create(update, target.toString(), Syntax.syntaxSPARQL_11);

        HttpException.check(target, getClient().patch(target, update)).close();

        return 0;
    }

}
