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
package com.atomgraph.linkeddatahub.server.util;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import org.junit.jupiter.api.Test;

/**
 * {@link ByteRange#parse(String, long)} against the uploads model's <code>select</code> (formal/uploads): each line of
 * <code>range-cases.tsv</code>, which <code>ldh-uploads range-cases</code> prints, is a range, a file length and what
 * the model selects - the whole file, a range of it, or 416 - and the parser has to select the same.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ByteRangeModelTest
{

    @Test
    public void testParseSelectsWhatTheModelSelects() throws Exception
    {
        List<String> lines;
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(getClass().getResourceAsStream("range-cases.tsv"), StandardCharsets.UTF_8)))
        {
            lines = reader.lines().filter(line -> !line.isBlank()).toList();
        }
        assertFalse(lines.isEmpty());

        for (String line : lines)
        {
            String[] fields = line.split("\t");
            String header = fields[0], expected = fields[2];
            long length = Long.parseLong(fields[1]);

            String selected;
            try
            {
                Optional<ByteRange> range = ByteRange.parse(header, length);
                selected = range.map(r -> r.getFirst() + "-" + r.getLast()).orElse("whole");
            }
            catch (ByteRange.NotSatisfiableException ex)
            {
                selected = "416";
            }

            assertEquals(expected, selected, header + " on " + length + " bytes");
        }
    }

}
