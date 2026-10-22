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

package com.atomgraph.linkeddatahub.cli.http;

import jakarta.ws.rs.core.Response;
import java.net.URI;

/**
 * Thrown when the server responds with a status other than success, including a redirect, which the client
 * does not follow.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class HttpException extends RuntimeException
{

    private static final int BODY_EXCERPT_LENGTH = 1024;

    private final int status;
    private final URI uri;

    /**
     * Constructs the exception.
     *
     * @param status HTTP status code
     * @param reasonPhrase HTTP reason phrase
     * @param uri request URI
     * @param body response body excerpt or redirect location (can be empty)
     */
    public HttpException(int status, String reasonPhrase, URI uri, String body)
    {
        super("HTTP " + status + " " + reasonPhrase + " — " + uri + (body == null || body.isBlank() ? "" : "\n" + body));
        this.status = status;
        this.uri = uri;
    }

    /**
     * Throws unless the response has a success (2xx) status, otherwise returns it.
     * A redirect is a failure too: the client does not follow redirects, so a 3xx means the request was not
     * carried out where it was sent - a <code>PUT</code> to a URI without a trailing slash is answered
     * <code>308</code> and writes nothing. Its <code>Location</code> goes into the message.
     *
     * @param uri request URI (for the error message)
     * @param response response to check
     * @return the same response
     */
    public static Response check(URI uri, Response response)
    {
        if (response.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL) return response;

        throw failure(uri, response);
    }

    /**
     * Throws unless the response has a success (2xx) or <code>303 See Other</code> status, otherwise returns it.
     * For writes: a <code>303</code> to a write says that it was carried out and where its result can be read.
     *
     * @param uri request URI (for the error message)
     * @param response response to check
     * @return the same response
     */
    public static Response checkWrite(URI uri, Response response)
    {
        if (response.getStatus() == Response.Status.SEE_OTHER.getStatusCode()) return response;

        return check(uri, response);
    }

    /**
     * Throws unless the response has a success (2xx) status, or a redirect (3xx) status carrying a
     * <code>Location</code>, otherwise returns it. For requests that ask for the redirect itself, such as a
     * Memento TimeGate's, or that only report the status.
     *
     * @param uri request URI (for the error message)
     * @param response response to check
     * @return the same response
     */
    public static Response checkRedirect(URI uri, Response response)
    {
        if (response.getStatusInfo().getFamily() == Response.Status.Family.REDIRECTION && response.getLocation() != null) return response;

        return check(uri, response);
    }

    /**
     * Closes an unsuccessful response and returns the exception describing it: the <code>Location</code> of a
     * redirect, or an excerpt of the body of an error.
     *
     * @param uri request URI
     * @param response unsuccessful response
     * @return exception
     */
    private static HttpException failure(URI uri, Response response)
    {
        String detail = "";
        try
        {
            if (response.getStatusInfo().getFamily() == Response.Status.Family.REDIRECTION)
                detail = response.getLocation() != null ? "Location: " + response.getLocation() : "";
            else
            {
                detail = response.readEntity(String.class);
                if (detail.length() > BODY_EXCERPT_LENGTH) detail = detail.substring(0, BODY_EXCERPT_LENGTH) + "…";
            }
        }
        catch (Exception ex)
        {
            // body is unreadable - leave the excerpt empty
        }
        finally
        {
            response.close();
        }

        return new HttpException(response.getStatus(), response.getStatusInfo().getReasonPhrase(), uri, detail);
    }

    /**
     * Returns the HTTP status code.
     *
     * @return status code
     */
    public int getStatus()
    {
        return status;
    }

    /**
     * Returns the request URI.
     *
     * @return request URI
     */
    public URI getUri()
    {
        return uri;
    }

}
