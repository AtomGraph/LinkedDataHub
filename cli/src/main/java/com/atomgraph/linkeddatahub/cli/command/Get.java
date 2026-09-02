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
import com.atomgraph.linkeddatahub.cli.util.Mementos;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import picocli.CommandLine.ArgGroup;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Parameters;

/**
 * Retrieves an RDF description. Mirrors <code>bin/get.sh</code>, extended with the RFC 7089 Memento
 * roles the document serves: a historical version, its version history and its TimeGate.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "get", description = "Retrieves RDF description.")
public class Get extends BaseCommand
{

    @Option(names = "--accept", paramLabel = "MEDIA_TYPE", description = "Requested media type (e.g. text/turtle). Required unless --timegate is given.")
    private String accept;

    @Option(names = "--head", description = "Requested headers only, no body (HEAD method)")
    private boolean head;

    @ArgGroup(exclusive = true)
    private Memento memento;

    @Option(names = "--datetime", paramLabel = "DATETIME", description = "Datetime the TimeGate negotiates on, RFC 1123 or ISO 8601 (requires --timegate)")
    private String datetime;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    /** The Memento role addressed instead of the document itself. The three are mutually exclusive. */
    static class Memento
    {

        @Option(names = "--version", paramLabel = "SHA", required = true, description = "Commit SHA of the historical version to retrieve")
        private String version;

        @Option(names = "--timemap", required = true, description = "Retrieve the version history (TimeMap) instead of the document")
        private boolean timeMap;

        @Option(names = "--timegate", required = true, description = "Negotiate on datetime and print the URI of the selected version")
        private boolean timeGate;

    }

    @Override
    public Integer call() throws Exception
    {
        boolean timeGate = memento != null && memento.timeGate;

        if (datetime != null && !timeGate) throw new ParameterException(getSpec().commandLine(), "Option '--datetime' requires '--timegate'");
        // a TimeGate redirect has no representation of its own, so it is the one request that needs no media type
        if (accept == null && !timeGate) throw new ParameterException(getSpec().commandLine(), "Missing required option: '--accept=MEDIA_TYPE'");

        URI uri = requestURI();
        MediaType[] acceptedTypes = accept != null ? new MediaType[] { MediaType.valueOf(accept) } : new MediaType[0];

        MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();
        if (datetime != null) headers.putSingle(Mementos.ACCEPT_DATETIME_HEADER, Mementos.acceptDatetime(datetime));

        if (head)
            try (Response response = HttpException.check(uri, getClient().head(uri, acceptedTypes, headers)))
            {
                print("HTTP " + response.getStatus() + " " + response.getStatusInfo().getReasonPhrase());
                response.getStringHeaders().forEach((name, values) -> values.forEach(value -> print(name + ": " + value)));
            }
        else if (timeGate)
            try (Response response = HttpException.check(uri, getClient().get(uri, acceptedTypes, headers)))
            {
                print(mementoURI(response));
            }
        else
            printBody(HttpException.check(uri, getClient().get(uri, acceptedTypes, headers)));

        return 0;
    }

    /**
     * Returns the URI of the Memento a TimeGate redirected to.
     *
     * @param response TimeGate response
     * @return Memento URI, with the logical origin restored when the request went through a proxy
     */
    private URI mementoURI(Response response)
    {
        URI location = response.getLocation();
        if (location == null) throw new IllegalStateException("TimeGate <" + requestURI() + "> did not redirect to a version of <" + target + ">");

        return getEffectiveProxy() != null ? URIRewriter.rewrite(location, target) : location;
    }

    /**
     * Returns the URI requested: the target document, or one of the Memento roles it serves.
     *
     * @return request URI
     */
    private URI requestURI()
    {
        if (memento == null) return target;
        if (memento.version != null) return Mementos.version(target, memento.version);
        if (memento.timeMap) return Mementos.timeMap(target);

        return Mementos.timeGate(target);
    }

}
