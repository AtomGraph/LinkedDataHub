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

package com.atomgraph.linkeddatahub.cli.command.imports;

import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.http.LDHClient;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.PrintWriter;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import picocli.CommandLine.Option;

/**
 * The <code>--wait</code> option of the import commands: an import runs in the background on the server, and this
 * waits for it to end and reports how it ended.
 * <p>
 * The platform adds <code>prov:endedAtTime</code> to the import when it finishes, and its outcome is an entity that
 * points back at it with <code>prov:wasGeneratedBy</code>: a <code>void:Dataset</code> with a triple count on success,
 * one with a <code>dct:description</code> message on failure.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportWait
{

    private static final MediaType[] ACCEPT_NTRIPLES = { com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE };
    private static final String PROV = "http://www.w3.org/ns/prov#";
    private static final Property ENDED_AT_TIME = ResourceFactory.createProperty(PROV + "endedAtTime");
    private static final Property WAS_GENERATED_BY = ResourceFactory.createProperty(PROV + "wasGeneratedBy");
    private static final Property TRIPLES = ResourceFactory.createProperty("http://rdfs.org/ns/void#triples");
    /** Interval between two reads of the import document, in milliseconds */
    private static final long POLL_INTERVAL = 5000;

    @Option(names = "--wait", description = "Wait for the import to end; exits 1 if it failed or timed out")
    private boolean wait;

    @Option(names = "--timeout", defaultValue = "1200", paramLabel = "SECONDS", description = "How long --wait waits (default: ${DEFAULT-VALUE})")
    private long timeout;

    /**
     * Returns true if the import should be waited for.
     *
     * @return true with <code>--wait</code>
     */
    public boolean isWait()
    {
        return wait;
    }

    /**
     * Waits for an import to end, polling its document.
     *
     * @param client HTTP client
     * @param importURI URI of the import resource
     * @param err stream for progress and errors
     * @return exit code: 0 if the import ended without errors, 1 if it failed or did not end in time
     * @throws InterruptedException if the wait is interrupted
     * @throws java.net.URISyntaxException if the import URI is malformed
     */
    public int await(LDHClient client, URI importURI, PrintWriter err) throws InterruptedException, java.net.URISyntaxException
    {
        URI doc = new URI(importURI.getScheme(), importURI.getSchemeSpecificPart(), null); // the document the import is in
        long deadline = System.currentTimeMillis() + timeout * 1000;

        while (true)
        {
            Model model;
            try (Response response = HttpException.check(doc, client.get(doc, ACCEPT_NTRIPLES)))
            {
                model = response.readEntity(Model.class);
            }

            Resource imp = model.createResource(importURI.toString());
            if (imp.hasProperty(ENDED_AT_TIME)) return outcome(model, imp, err);

            if (System.currentTimeMillis() >= deadline)
            {
                err.println("Timed out waiting for <" + importURI + ">");
                return 1;
            }

            Thread.sleep(POLL_INTERVAL);
        }
    }

    /**
     * Reports the outcome of an ended import.
     *
     * @param model import document model
     * @param imp import resource
     * @param err stream for the report
     * @return exit code: 0 without errors, 1 with any
     */
    protected static int outcome(Model model, Resource imp, PrintWriter err)
    {
        List<String> errors = new ArrayList<>();
        long triples = 0;

        for (Resource entity : model.listSubjectsWithProperty(WAS_GENERATED_BY, imp).toList())
        {
            if (entity.hasProperty(DCTerms.description)) errors.add(entity.getProperty(DCTerms.description).getString());
            if (entity.hasProperty(TRIPLES)) triples += entity.getProperty(TRIPLES).getLong();
        }

        if (!errors.isEmpty())
        {
            err.println("Import <" + imp + "> failed:");
            errors.forEach(err::println);
            return 1;
        }

        err.println("Import <" + imp + "> done: " + triples + " triples");
        return 0;
    }

}
