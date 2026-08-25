/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.writer;

import com.atomgraph.linkeddatahub.client.GitHubClient;
import com.atomgraph.linkeddatahub.server.util.GraphVersioningService;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.apache.jena.rdf.model.Model;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Tests the link-format serialization of TimeMaps.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class TimeMapWriterTest
{

    private static final URI GRAPH = URI.create("https://localhost:4443/doc/");

    private String write(Model timeMap) throws IOException
    {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        new TimeMapWriter().writeTo(timeMap, Model.class, null, null, TimeMapWriter.APPLICATION_LINK_FORMAT_TYPE, null, out);
        return out.toString(StandardCharsets.UTF_8);
    }

    @Test
    public void testLinkFormat() throws IOException
    {
        // commit history is most recent first
        Model timeMap = GraphVersioningService.toTimeMap(GRAPH, List.of(
            new GitHubClient.CommitInfo("sha-3", Instant.parse("2026-08-17T12:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T11:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this")));

        assertEquals("""
            <https://localhost:4443/doc/>;rel="original",
            <https://localhost:4443/doc/?timemap>;rel="self";type="application/link-format";from="Mon, 17 Aug 2026 10:00:00 GMT";until="Mon, 17 Aug 2026 12:00:00 GMT",
            <https://localhost:4443/doc/?version=sha-1>;rel="first memento";datetime="Mon, 17 Aug 2026 10:00:00 GMT",
            <https://localhost:4443/doc/?version=sha-2>;rel="memento";datetime="Mon, 17 Aug 2026 11:00:00 GMT",
            <https://localhost:4443/doc/?version=sha-3>;rel="last memento";datetime="Mon, 17 Aug 2026 12:00:00 GMT\"""",
            write(timeMap));
    }

    @Test
    public void testSingleMementoIsBothFirstAndLast() throws IOException
    {
        Model timeMap = GraphVersioningService.toTimeMap(GRAPH, List.of(
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this")));

        assertEquals("""
            <https://localhost:4443/doc/>;rel="original",
            <https://localhost:4443/doc/?timemap>;rel="self";type="application/link-format";from="Mon, 17 Aug 2026 10:00:00 GMT";until="Mon, 17 Aug 2026 10:00:00 GMT",
            <https://localhost:4443/doc/?version=sha-1>;rel="first last memento";datetime="Mon, 17 Aug 2026 10:00:00 GMT\"""",
            write(timeMap));
    }

    @Test
    public void testTimeGateIsListed() throws IOException
    {
        Model timeMap = GraphVersioningService.toTimeMap(GRAPH, List.of(
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this")));

        // the TimeGate comes from the request rather than the model, since PROV has no term for it
        TimeMapWriter writer = new TimeMapWriter()
        {
            @Override
            protected Optional<URI> getTimeGateURI()
            {
                return Optional.of(URI.create("https://localhost:4443/doc/?timegate"));
            }
        };

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        writer.writeTo(timeMap, Model.class, null, null, TimeMapWriter.APPLICATION_LINK_FORMAT_TYPE, null, out);

        assertEquals(true, out.toString(StandardCharsets.UTF_8).contains("<https://localhost:4443/doc/?timegate>;rel=\"timegate\""));
    }

    @Test
    public void testDayOfMonthIsZeroPadded() throws IOException
    {
        // RFC 7089 specifies date1 = 2DIGIT SP month SP 4DIGIT, unlike DateTimeFormatter.RFC_1123_DATE_TIME
        Model timeMap = GraphVersioningService.toTimeMap(GRAPH, List.of(
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-03T10:00:00Z"), "https://localhost/agent#this")));

        assertEquals(true, write(timeMap).contains("datetime=\"Mon, 03 Aug 2026 10:00:00 GMT\""));
    }

}
