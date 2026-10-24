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

import java.util.Date;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the parsing of <code>Range</code> and <code>If-Range</code> per RFC 9110 §14 and §13.1.5.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ByteRangeTest
{

    private static final long LENGTH = 1024;

    private static Optional<ByteRange> parse(String header) throws ByteRange.NotSatisfiableException
    {
        return ByteRange.parse(header, LENGTH);
    }

    @Test
    public void absentHeaderIsIgnored() throws Exception
    {
        assertEquals(Optional.empty(), parse(null));
    }

    @Test
    public void closedRange() throws Exception
    {
        ByteRange range = parse("bytes=100-141").get();
        assertEquals(100, range.getFirst());
        assertEquals(141, range.getLast());
        assertEquals(42, range.getLength());
        assertEquals("bytes 100-141/1024", range.contentRange(LENGTH));
    }

    @Test
    public void unitIsCaseInsensitiveAndWhitespaceTolerated() throws Exception
    {
        assertEquals(Optional.of(new ByteRange(0, 1)), parse("Bytes=0-1"));
        assertEquals(Optional.of(new ByteRange(0, 1)), parse("bytes= 0-1 "));
        assertEquals(Optional.of(new ByteRange(0, 1)), parse("bytes=0-1,")); // empty list elements are allowed
    }

    @Test
    public void lastPositionPastEndIsClamped() throws Exception
    {
        assertEquals(Optional.of(new ByteRange(1000, 1023)), parse("bytes=1000-5000"));
        assertEquals(Optional.of(new ByteRange(0, 1023)), parse("bytes=0-99999999999999999999999"));
    }

    @Test
    public void openRangeRunsToTheEnd() throws Exception
    {
        assertEquals(Optional.of(new ByteRange(0, 1023)), parse("bytes=0-"));
        assertEquals(Optional.of(new ByteRange(1000, 1023)), parse("bytes=1000-"));
    }

    @Test
    public void suffixRange() throws Exception
    {
        ByteRange range = parse("bytes=-500").get();
        assertEquals(524, range.getFirst());
        assertEquals(1023, range.getLast());
        assertEquals(500, range.getLength());
    }

    @Test
    public void suffixLongerThanRepresentationSelectsAll() throws Exception
    {
        assertEquals(Optional.of(new ByteRange(0, 1023)), parse("bytes=-5000"));
    }

    @Test
    public void zeroSuffixIsNotSatisfiable()
    {
        assertThrows(ByteRange.NotSatisfiableException.class, () -> parse("bytes=-0"));
    }

    @Test
    public void suffixOfEmptyRepresentationIsIgnored() throws Exception
    {
        assertEquals(Optional.empty(), ByteRange.parse("bytes=-5", 0));
    }

    @Test
    public void unknownUnitIsIgnored() throws Exception
    {
        assertEquals(Optional.empty(), parse("items=0-1"));
        assertEquals(Optional.empty(), parse("none=0-1"));
    }

    @Test
    public void malformedHeadersAreIgnored() throws Exception
    {
        assertEquals(Optional.empty(), parse("bytes"));
        assertEquals(Optional.empty(), parse("bytes="));
        assertEquals(Optional.empty(), parse("bytes=,"));
        assertEquals(Optional.empty(), parse("bytes=abc"));
        assertEquals(Optional.empty(), parse("bytes=-"));
        assertEquals(Optional.empty(), parse("bytes=1-2-3"));
        assertEquals(Optional.empty(), parse("bytes=+1-2"));
        assertEquals(Optional.empty(), parse("bytes=1 - 2"));
        assertEquals(Optional.empty(), parse(""));
    }

    @Test
    public void multipleRangesAreIgnored() throws Exception
    {
        assertEquals(Optional.empty(), parse("bytes=0-1,4-5"));
        assertEquals(Optional.empty(), parse("bytes=0-1, -5"));
    }

    @Test
    public void invertedRangeIsNotSatisfiable()
    {
        ByteRange.NotSatisfiableException ex = assertThrows(ByteRange.NotSatisfiableException.class, () -> parse("bytes=5-4"));
        assertEquals(LENGTH, ex.getCompleteLength());
    }

    @Test
    public void firstPositionAtOrPastEndIsNotSatisfiable()
    {
        assertThrows(ByteRange.NotSatisfiableException.class, () -> parse("bytes=1024-"));
        assertThrows(ByteRange.NotSatisfiableException.class, () -> parse("bytes=1024-2000"));
        assertThrows(ByteRange.NotSatisfiableException.class, () -> parse("bytes=99999999999999999999999-"));
        assertThrows(ByteRange.NotSatisfiableException.class, () -> ByteRange.parse("bytes=0-0", 0));
    }

    @Test
    public void unsatisfiedContentRange()
    {
        assertEquals("bytes */1024", ByteRange.unsatisfiedContentRange(LENGTH));
    }

    @Test
    public void ifRangeAbsentMatches()
    {
        assertTrue(ByteRange.ifRangeMatches(null, "abc", new Date(0)));
    }

    @Test
    public void ifRangeEntityTag()
    {
        assertTrue(ByteRange.ifRangeMatches("\"abc\"", "abc", new Date(0)));
        assertTrue(ByteRange.ifRangeMatches(" \"abc\" ", "abc", new Date(0)));
        assertFalse(ByteRange.ifRangeMatches("\"abd\"", "abc", new Date(0)));
        assertFalse(ByteRange.ifRangeMatches("W/\"abc\"", "abc", new Date(0))); // weak never matches
        assertFalse(ByteRange.ifRangeMatches("\"abc", "abc", new Date(0)));
        assertFalse(ByteRange.ifRangeMatches("\"", "abc", new Date(0)));
    }

    @Test
    public void ifRangeDate()
    {
        Date lastModified = new Date(784111777_000L + 456); // Sun, 06 Nov 1994 08:49:37 GMT, with milliseconds
        assertTrue(ByteRange.ifRangeMatches("Sun, 06 Nov 1994 08:49:37 GMT", "abc", lastModified));
        assertFalse(ByteRange.ifRangeMatches("Sun, 06 Nov 1994 08:49:38 GMT", "abc", lastModified));
        assertFalse(ByteRange.ifRangeMatches("Sun, 06 Nov 1994 08:49:36 GMT", "abc", lastModified));
        assertFalse(ByteRange.ifRangeMatches("Sun, 06 Nov 1994 08:49:37 GMT", "abc", null));
    }

    @Test
    public void ifRangeGarbageDoesNotMatch()
    {
        assertFalse(ByteRange.ifRangeMatches("yesterday", "abc", new Date(0)));
        assertFalse(ByteRange.ifRangeMatches("", "abc", new Date(0)));
    }

}
