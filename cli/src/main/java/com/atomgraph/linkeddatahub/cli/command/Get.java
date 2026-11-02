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
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Link;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.Optional;
import java.util.function.Supplier;
import picocli.CommandLine.ArgGroup;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Parameters;

/**
 * Retrieves an RDF description. Also addresses the RFC 7089 Memento
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

    /** How many times a TimeGate that asks to come back (503 with Retry-After) is asked again */
    static final int TIMEGATE_ATTEMPTS = 30;

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
            try (Response response = HttpException.checkRedirect(uri, timeGate ? waited(() -> getClient().head(uri, acceptedTypes, headers)) : getClient().head(uri, acceptedTypes, headers)))
            {
                print("HTTP " + response.getStatus() + " " + response.getStatusInfo().getReasonPhrase());
                response.getStringHeaders().forEach((name, values) -> values.forEach(value -> print(name + ": " + value)));
            }
        else if (timeGate)
            try (Response response = HttpException.checkRedirect(uri, waited(() -> getClient().get(uri, acceptedTypes, headers))))
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
     * @return Memento URI; a proxied request keeps its logical Host, so the platform answers with the logical origin
     */
    private URI mementoURI(Response response)
    {
        URI location = response.getLocation();
        if (location == null) throw new IllegalStateException("TimeGate <" + requestURI() + "> did not redirect to a version of <" + target + ">");

        return location;
    }

    /**
     * Returns the URI requested: the target document, or one of the Memento roles it serves. The TimeMap and the TimeGate
     * are the ones the document advertises in its <code>Link</code> header (RFC 7089), and the platform's query
     * parameters only when it advertises none.
     *
     * @return request URI
     */
    private URI requestURI()
    {
        if (memento == null) return target;
        if (memento.version != null) return Mementos.version(target, memento.version);
        if (memento.timeMap) return advertised("timemap").orElseGet(() -> Mementos.timeMap(target));

        return advertised("timegate").orElseGet(() -> Mementos.timeGate(target));
    }

    /**
     * Returns the URI the target document links to with a relation, read from the headers of a <code>HEAD</code> of it.
     *
     * @param rel link relation
     * @return linked URI, resolved against the document's
     */
    private Optional<URI> advertised(String rel)
    {
        try (Response response = getClient().head(target, new MediaType[0]))
        {
            Link link = response.getLink(rel);
            return link == null ? Optional.empty() : Optional.of(target.resolve(link.getUri()));
        }
    }

    /**
     * Sends a TimeGate request, and again while the TimeGate asks to come back: it answers 503 with
     * <code>Retry-After</code> while the most recent change of the document is not yet in its version history.
     *
     * @param request the request, sent once per attempt
     * @return the first response that is not such a 503, or the last one
     * @throws InterruptedException if interrupted while waiting
     */
    private Response waited(Supplier<Response> request) throws InterruptedException
    {
        Response response = request.get();
        for (int attempt = 1; attempt < TIMEGATE_ATTEMPTS && response.getStatus() == Response.Status.SERVICE_UNAVAILABLE.getStatusCode(); attempt++)
        {
            String retryAfter = response.getHeaderString(HttpHeaders.RETRY_AFTER);
            if (retryAfter == null || !retryAfter.strip().matches("[0-9]+")) break;

            response.close();
            Thread.sleep(Math.max(1, Long.parseLong(retryAfter.strip())) * 1000);
            response = request.get();
        }

        return response;
    }

}
