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

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Tests the RDF/POST multipart encoding of {@link AddFile}: the field order is positional,
 * each <code>pu</code> must immediately precede its <code>ol</code>/<code>ou</code> value.
 */
public class AddFileMultiPartTest
{

    @TempDir
    Path tempDir;

    @Test
    public void fieldOrderIsPositional() throws Exception
    {
        Path file = tempDir.resolve("data.csv");
        Files.writeString(file, "a,b\n1,2\n");

        try (FormDataMultiPart multiPart = AddFile.buildMultiPart(file, "text/csv", "Data", null))
        {
            List<String> names = multiPart.getBodyParts().stream().
                map(part -> ((FormDataBodyPart)part).getName()).
                toList();

            assertEquals(List.of("rdf", "sb", "pu", "ol", "pu", "ol", "pu", "ou"), names);
            assertEquals("text/csv", multiPart.getBodyParts().get(3).getMediaType().toString());
        }
    }

    @Test
    public void descriptionAppendsTrailingPair() throws Exception
    {
        Path file = tempDir.resolve("data.csv");
        Files.writeString(file, "a,b\n1,2\n");

        try (FormDataMultiPart multiPart = AddFile.buildMultiPart(file, "text/csv", "Data", "Description"))
        {
            List<String> names = multiPart.getBodyParts().stream().
                map(part -> ((FormDataBodyPart)part).getName()).
                toList();

            assertEquals(List.of("rdf", "sb", "pu", "ol", "pu", "ol", "pu", "ou", "pu", "ol"), names);
        }
    }

}
