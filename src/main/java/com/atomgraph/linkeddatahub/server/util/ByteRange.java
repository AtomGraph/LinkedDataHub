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

import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Date;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A single satisfiable byte range of a representation, and the parsing of the <code>Range</code> and
 * <code>If-Range</code> request headers that select it (RFC 9110 §14 and §13.1.5).
 *
 * Pure: it knows the header values and the representation's length, validator and modification date,
 * and nothing about HTTP messages, so the server code decides what an outcome is answered with.
 *
 * {@link #parse(String, long)} has three outcomes:
 * <ul>
 * <li>a range - answer <code>206</code> with it;</li>
 * <li>empty - the header is ignored and the whole representation is answered with <code>200</code>:
 * a range unit other than <code>bytes</code> (§14.2: a server MUST ignore a range unit it does not
 * understand), a header that does not parse, or several ranges, which this server does not serve as
 * <code>multipart/byteranges</code> (§14.2 lets a server ignore the header);</li>
 * <li>{@link NotSatisfiableException} - answer <code>416</code> (§15.5.17): the first position is at or
 * past the end, a suffix length of zero, or a last position before the first.</li>
 * </ul>
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class ByteRange
{

    /** The only range unit understood */
    public static final String UNIT = "bytes";

    private static final Pattern INT_RANGE = Pattern.compile("([0-9]+)-([0-9]*)");
    private static final Pattern SUFFIX_RANGE = Pattern.compile("-([0-9]+)");

    private final long first;
    private final long last;

    /**
     * Constructs a range from inclusive positions.
     *
     * @param first first byte position
     * @param last last byte position, inclusive
     */
    public ByteRange(long first, long last)
    {
        if (first < 0 || last < first) throw new IllegalArgumentException("Invalid byte range " + first + "-" + last);
        this.first = first;
        this.last = last;
    }

    /**
     * Parses a <code>Range</code> header value against a representation of the given length.
     *
     * @param header the header value, or null when absent
     * @param completeLength the representation's length in bytes
     * @return the selected range, or empty when the header is to be ignored
     * @throws NotSatisfiableException when the range cannot be satisfied
     */
    public static Optional<ByteRange> parse(String header, long completeLength) throws NotSatisfiableException
    {
        if (header == null) return Optional.empty();

        int eq = header.indexOf('=');
        if (eq < 0) return Optional.empty(); // not a ranges-specifier

        String unit = header.substring(0, eq).trim();
        if (!UNIT.equalsIgnoreCase(unit)) return Optional.empty(); // range units are case-insensitive (§14.1)

        String spec = null;
        for (String element : header.substring(eq + 1).split(",", -1)) // 1#range-spec: empty list elements are allowed
        {
            String trimmed = element.trim();
            if (trimmed.isEmpty()) continue;
            if (spec != null) return Optional.empty(); // several ranges: ignored, the whole file is served
            spec = trimmed;
        }
        if (spec == null) return Optional.empty(); // no range-spec at all

        Matcher suffix = SUFFIX_RANGE.matcher(spec);
        if (suffix.matches())
        {
            long suffixLength = parsePosition(suffix.group(1));
            if (suffixLength == 0) throw new NotSatisfiableException(completeLength);
            if (completeLength == 0) return Optional.empty(); // nothing to select from: serve the empty representation
            return Optional.of(new ByteRange(Math.max(0, completeLength - suffixLength), completeLength - 1));
        }

        Matcher intRange = INT_RANGE.matcher(spec);
        if (!intRange.matches()) return Optional.empty();

        long first = parsePosition(intRange.group(1));
        long last = intRange.group(2).isEmpty() ? Long.MAX_VALUE : parsePosition(intRange.group(2));
        if (last < first) throw new NotSatisfiableException(completeLength);
        if (first >= completeLength) throw new NotSatisfiableException(completeLength);

        return Optional.of(new ByteRange(first, Math.min(last, completeLength - 1)));
    }

    /**
     * Evaluates an <code>If-Range</code> header value (RFC 9110 §13.1.5). The range is served only when
     * this returns true; otherwise the <code>Range</code> header is ignored.
     *
     * An entity tag matches by the strong comparison function, so a weak tag never matches. A date matches
     * when it equals the last modification date, to the second. Anything else does not match.
     *
     * @param header the header value, or null when absent
     * @param entityTag the representation's strong entity tag, opaque value without quotes
     * @param lastModified the representation's last modification date
     * @return true if the header is absent or its validator matches
     */
    public static boolean ifRangeMatches(String header, String entityTag, Date lastModified)
    {
        if (header == null) return true;

        String value = header.trim();
        if (value.startsWith("W/")) return false; // weak tags fail the strong comparison
        if (value.startsWith("\""))
            return value.length() >= 2 && value.endsWith("\"") && entityTag != null &&
                value.substring(1, value.length() - 1).equals(entityTag);

        if (lastModified == null) return false;
        try
        {
            long date = ZonedDateTime.parse(value, DateTimeFormatter.RFC_1123_DATE_TIME).toEpochSecond();
            return date == Math.floorDiv(lastModified.getTime(), 1000L);
        }
        catch (DateTimeParseException ex)
        {
            return false;
        }
    }

    /**
     * Parses a run of digits; a value too large for <code>long</code> saturates, which a position past
     * any representation length behaves like.
     */
    private static long parsePosition(String digits)
    {
        try
        {
            return Long.parseLong(digits);
        }
        catch (NumberFormatException ex)
        {
            return Long.MAX_VALUE;
        }
    }

    /**
     * Returns the <code>Content-Range</code> value of an unsatisfied range (§14.4).
     *
     * @param completeLength the representation's length in bytes
     * @return header value
     */
    public static String unsatisfiedContentRange(long completeLength)
    {
        return UNIT + " */" + completeLength;
    }

    /**
     * Returns the <code>Content-Range</code> value of this range (§14.4).
     *
     * @param completeLength the representation's length in bytes
     * @return header value
     */
    public String contentRange(long completeLength)
    {
        return UNIT + " " + getFirst() + "-" + getLast() + "/" + completeLength;
    }

    /**
     * Returns the first byte position.
     *
     * @return position
     */
    public long getFirst()
    {
        return first;
    }

    /**
     * Returns the last byte position, inclusive.
     *
     * @return position
     */
    public long getLast()
    {
        return last;
    }

    /**
     * Returns the number of bytes in this range.
     *
     * @return length
     */
    public long getLength()
    {
        return last - first + 1;
    }

    @Override
    public boolean equals(Object obj)
    {
        return obj instanceof ByteRange other && other.first == first && other.last == last;
    }

    @Override
    public int hashCode()
    {
        return Long.hashCode(first) * 31 + Long.hashCode(last);
    }

    @Override
    public String toString()
    {
        return UNIT + "=" + first + "-" + last;
    }

    /**
     * The requested range cannot be satisfied by the representation.
     */
    public static class NotSatisfiableException extends Exception
    {

        private final long completeLength;

        /**
         * Constructs exception.
         *
         * @param completeLength the representation's length in bytes
         */
        public NotSatisfiableException(long completeLength)
        {
            super("Range not satisfiable for a representation of " + completeLength + " bytes");
            this.completeLength = completeLength;
        }

        /**
         * Returns the representation's length.
         *
         * @return length in bytes
         */
        public long getCompleteLength()
        {
            return completeLength;
        }

    }

}
