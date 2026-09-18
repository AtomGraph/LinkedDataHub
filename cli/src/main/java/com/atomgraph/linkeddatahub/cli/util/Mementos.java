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

package com.atomgraph.linkeddatahub.cli.util;

import java.net.URI;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.DateTimeException;
import java.util.Locale;

/**
 * Addressing of the RFC 7089 Memento roles a LinkedDataHub document serves: a historical version
 * (Memento), its version history (TimeMap) and its datetime negotiation endpoint (TimeGate).
 * Each is a query parameter on the document URI itself.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Mementos
{

    /** Name of the query parameter that selects a historical version by commit SHA */
    public static final String VERSION_PARAM_NAME = "version";

    /** Name of the query parameter that addresses the version history */
    public static final String TIMEMAP_PARAM_NAME = "timemap";

    /** Name of the query parameter that addresses the TimeGate */
    public static final String TIMEGATE_PARAM_NAME = "timegate";

    /** Name of the request header conveying the datetime a TimeGate negotiates on */
    public static final String ACCEPT_DATETIME_HEADER = "Accept-Datetime";

    /**
     * RFC 1123 datetime in GMT with a zero-padded day of month, which the RFC 7089 grammar requires
     * where {@link DateTimeFormatter#RFC_1123_DATE_TIME} leaves it unpadded. The same format the
     * server writes <code>Memento-Datetime</code> and TimeMap datetimes in.
     */
    public static final DateTimeFormatter RFC_1123_GMT = DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.US).
        withZone(ZoneId.of("GMT"));

    private Mementos() { }

    /**
     * Returns the URI of a document's historical version.
     *
     * @param target document URI
     * @param sha commit SHA
     * @return Memento URI
     */
    public static URI version(URI target, String sha)
    {
        return queryParam(target, VERSION_PARAM_NAME + "=" + sha);
    }

    /**
     * Returns the URI of a document's version history.
     *
     * @param target document URI
     * @return TimeMap URI
     */
    public static URI timeMap(URI target)
    {
        return queryParam(target, TIMEMAP_PARAM_NAME);
    }

    /**
     * Returns the URI of a document's TimeGate.
     *
     * @param target document URI
     * @return TimeGate URI
     */
    public static URI timeGate(URI target)
    {
        return queryParam(target, TIMEGATE_PARAM_NAME);
    }

    /**
     * Appends a query parameter to a URI, before its fragment. Valueless parameters keep the bare
     * form the server advertises them in, e.g. <code>?timemap</code> rather than <code>?timemap=</code>.
     *
     * @param uri URI to append to
     * @param param parameter, either a bare name or <code>name=value</code>
     * @return URI with the parameter appended
     */
    private static URI queryParam(URI uri, String param)
    {
        String string = uri.toString();
        int hash = string.indexOf('#');
        String fragment = hash == -1 ? "" : string.substring(hash);

        return URI.create((hash == -1 ? string : string.substring(0, hash)) +
            (uri.getRawQuery() == null ? "?" : "&") + param + fragment);
    }

    /**
     * Formats a datetime as the <code>Accept-Datetime</code> header value. Accepts RFC 1123
     * (<code>Wed, 20 Aug 2026 10:00:00 GMT</code>) as well as ISO 8601
     * (<code>2026-08-20T10:00:00Z</code>), so that timestamps read out of a TimeMap, where they are
     * <code>xsd:dateTime</code>, can be handed back without conversion.
     *
     * @param datetime datetime in either format
     * @return RFC 1123 datetime in GMT
     */
    public static String acceptDatetime(String datetime)
    {
        return RFC_1123_GMT.format(parse(datetime));
    }

    private static Instant parse(String datetime)
    {
        try
        {
            return Instant.from(DateTimeFormatter.RFC_1123_DATE_TIME.parse(datetime));
        }
        catch (DateTimeException ex)
        {
            try
            {
                return OffsetDateTime.parse(datetime).toInstant();
            }
            catch (DateTimeException ex2)
            {
                throw new IllegalArgumentException("Value '" + datetime + "' is neither an RFC 1123 nor an ISO 8601 datetime");
            }
        }
    }

}
